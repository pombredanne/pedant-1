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

class TestContainsUnreachableCode < Test::Unit::TestCase
  include Pedant::Test

  def test_top
    check(
      :pass,
      :CheckContainsUnreachableCode,
      %q||
    )

    check(
      :fail,
      :CheckContainsUnreachableCode,
      %q|exit(); foo();|
    )

    check(
      :fail,
      :CheckContainsUnreachableCode,
      %q|audit(); foo();|
    )

    check(
      :fail,
      :CheckContainsUnreachableCode,
      %q|return; foo();|
    )

    check(
      :fail,
      :CheckContainsUnreachableCode,
      %q|break; foo();|
    )

    check(
      :fail,
      :CheckContainsUnreachableCode,
      %q|continue; foo();|
    )
  end

  def test_block
    check(
      :pass,
      :CheckContainsUnreachableCode,
      %q|{}|
    )

    check(
      :fail,
      :CheckContainsUnreachableCode,
      %q|{ exit(); foo(); }|
    )

    check(
      :fail,
      :CheckContainsUnreachableCode,
      %q|{ return; foo(); }|
    )

    check(
      :fail,
      :CheckContainsUnreachableCode,
      %q|{ break; foo(); }|
    )

    check(
      :fail,
      :CheckContainsUnreachableCode,
      %q|{ continue; foo(); }|
    )
  end

  # Plugins that are deprecated will have a bit of code inserted to
  # prevent the body of the plugin from running. We should not flag
  # this specific call to exit().
  def test_deprecated_plugin_exit
    check(
      :pass,
      :CheckContainsUnreachableCode,
      %q|{ exit(0, "This plugin has been deprecated"); foo(); }|
    )
  end

  # exit() is a special case in this check, because it's a function instead of a
  # language keyword.
  def test_indexed_exit
    check(
      :pass,
      :CheckContainsUnreachableCode,
      %q|{ exit.foo(); foo(); }|
    )
  end
  
  def audit_indexed_exit
    check(
      :pass,
      :CheckContainsUnreachableCode,
      %q|{ audit.foo(); foo(); }|
    )
  end
end
