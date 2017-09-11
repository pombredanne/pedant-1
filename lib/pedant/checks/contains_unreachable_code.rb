################################################################################
# Copyright (c) 2011-2014, Tenable Network Security
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
################################################################################

module Pedant
  class CheckContainsUnreachableCode < Check
    def self.requires
      super + [:trees]
    end

    def check(file, tree)
      def check_statements(file, list)
        list.each do |node|
          # Is this an exit() call that's used to deprecate the plugin? If so,
          # we'll ignore it and check the rest of the plugin.
          # These look like:
          #   exit(0, "This plugin has been deprecated");
          # Some plugins (like the Slackware plugins) just do: exit(0);
          # But, they are old and have been deprecated forever and will
          # probably never be changed or reenabled.
          next if node.is_a?(Nasl::Call) and
            node.name.ident.name == 'exit' and
            node.args.length == 2 and
            node.args[1].expr.is_a?(Nasl::String) and
            node.args[1].expr.text =~ /plugin has been deprecated|patch has been replaced/i

          # Check if the Node is capable of jumping out of the Block, without
          # resuming where it left off (i.e., Call). The exception is exit(),
          # which is a builtin Function that terminates execution.
          if node.is_a?(Nasl::Break) || node.is_a?(Nasl::Continue) ||
             node.is_a?(Nasl::Return) || (node.is_a?(Nasl::Call) &&
             (node.name.ident.name == 'exit' ||
              node.name.ident.name == 'audit') && node.name.indexes == [])
            # If this is not the final node in the list, then there is
            # absolutely no way for the later nodes to be accessed.
            return node if node != list.last
          end
        end
        return nil
      end

      # Unreachable statements occur only when there are sequential lists of
      # instructions. In layers deeper than the outermost level of indentation,
      # this only occurs in Blocks.
      tree.all(:Block).each do |blk|
        node = check_statements(file, blk.body)
        if not node.nil?
          fail
          report(:error, node.context(blk))
        end
      end

      # The main body of a file is not a Block, so it must be considered
      # separately.
      node = check_statements(file, tree)
      if not node.nil?
        fail
        report(:error, node.context(node))
      end
    end

    def run
      # This check will pass by default.
      pass

      # Run this check on the tree from every file.
      @kb[:trees].each { |file, tree| check(file, tree) }
    end
  end
end
