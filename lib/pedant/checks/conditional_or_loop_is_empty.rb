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
  class CheckConditionalOrLoopIsEmpty < Check
    def self.requires
      super + [:trees]
    end

    def check(file, tree)
      # All of the loops have a body attribute, so they can be checked together.
      [:For, :Foreach, :Repeat, :While].each do |cls|
        tree.all(cls).each do |node|
          next unless node.body.is_a? Nasl::Empty

          fail

          report(:error, "#{cls} loop in #{file} has an empty statement as its body.")
          report(:error, node.body.context(node))
        end
      end

      # An If statement may has two branches, each of which need to be checked.
      # This will not cause false positives on If statements without else
      # clauses, because those branches will be nil.
      tree.all(:If).each do |node|
        [:true, :false].each do |name|
          branch = node.send(name)

          next if branch.nil?
          next unless branch.is_a? Nasl::Empty

          fail

          report(:error, "If statement in #{file} has an empty statement as #{name} branch.")
          report(:error, branch.context(node))
        end
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
