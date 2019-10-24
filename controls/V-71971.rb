# encoding: utf-8
#
# TODO we really do need an `semanage` resource.
# Will need to be changed to reflect list of authorized system accounts
admin_logins = input(
  'admin_logins',
  value: [],
  description: "System accounts that support approved system activities."
)

selogin_context_enforcement = attribute(
  'selogin_context_enforcement',
  value: 'enabled',
  description: "Verify user accounts are mapped to an SELinux login context."
)

control "V-71971" do
  title "The operating system must prevent non-privileged users from executing
privileged functions to include disabling, circumventing, or altering
implemented security safeguards/countermeasures."
  desc  "
    Preventing non-privileged users from executing privileged functions
mitigates the risk that unauthorized individuals or processes may gain
unnecessary access to information or privileges.

    Privileged functions include, for example, establishing accounts,
performing system integrity checks, or administering cryptographic key
management activities. Non-privileged users are individuals who do not possess
appropriate authorizations. Circumventing intrusion detection and prevention
mechanisms or malicious code protection mechanisms are examples of privileged
functions that require protection from non-privileged users.
  "
  impact 0.5

  tag "gtitle": "SRG-OS-000324-GPOS-00125"
  tag "gid": "V-71971"
  tag "rid": "SV-86595r1_rule"
  tag "stig_id": "RHEL-07-020020"
  tag "cci": ["CCI-002165", "CCI-002235"]
  tag "documentable": false
  tag "nist": ["AC-3 (4)", "AC-6 (10)", "Rev_4"]
  tag "subsystems": ["selinux"]
  desc "check", "Verify the operating system prevents non-privileged users from
executing privileged functions to include disabling, circumventing, or altering
implemented security safeguards/countermeasures.

Get a list of authorized users (other than System Administrator and guest
accounts) for the system.

Check the list against the system by using the following command:

# semanage login -l | more
Login Name  SELinux User   MLS/MCS Range  Service
__default__  user_u    s0-s0:c0.c1023   *
root   unconfined_u   s0-s0:c0.c1023   *
system_u  system_u   s0-s0:c0.c1023   *
joe  staff_u   s0-s0:c0.c1023   *

All administrators must be mapped to the \"sysadm_u\" or \"staff_u\" users with
the appropriate domains (sysadm_t and staff_t).

All authorized non-administrative users must be mapped to the \"user_u\" role
or the appropriate domain (user_t).

If they are not mapped in this way, this is a finding."
  desc "fix", "Configure the operating system to prevent non-privileged users
from executing privileged functions to include disabling, circumventing, or
altering implemented security safeguards/countermeasures.

Use the following command to map a new user to the \"sysdam_u\" role:

#semanage login -a -s sysadm_u <username>

Use the following command to map an existing user to the \"sysdam_u\" role:

#semanage login -m -s sysadm_u <username>

Use the following command to map a new user to the \"staff_u\" role:

#semanage login -a -s staff_u <username>

Use the following command to map an existing user to the \"staff_u\" role:

#semanage login -m -s staff_u <username>

Use the following command to map a new user to the \"user_u\" role:

# semanage login -a -s user_u <username>

Use the following command to map an existing user to the \"user_u\" role:

# semanage login -m -s user_u <username>

# For example, run the following command as the Linux root user to change the default mapping from unconfined_u to user_u:
# semanage login -m -S targeted -s \"user_u\" -r s0 __default__
#
# unconfined_u a specific user
# semanage login -a -s unconfined_u ec2-user
#
# To change back to the default behavior, run the following command as the Linux root user to map the __default__ login to the SELinux unconfined_u user:
# semanage login -m -S targeted -s \"unconfined_u\" -r s0-s0:c0.c1023 __default__
#
# DEFAULT for Redhat 7.6
# [root@somenode]# semanage login -l
# 
# Login Name           SELinux User         MLS/MCS Range        Service
# 
# __default__          unconfined_u         s0-s0:c0.c1023       *
# root                 unconfined_u         s0-s0:c0.c1023       *
# system_u             system_u             s0-s0:c0.c1023       *
# "

  tag "fix_id": "F-78323r1_fix"

  describe command('selinuxenabled') do
    its('exist?') { should be true }
    its('exit_status') { should eq 0 }
  end

  describe command('semanage') do
    its('exist?') { should be true }
  end

  semanage_results = command('semanage login -l -n')

  describe semanage_results do
    its('stdout.lines') { should_not be_empty }
  end

  semanage_results.stdout.lines.each do |result|
    login, seuser = result.split(/\s+/)

    # Skip Blank Lines
    next unless login

    # Next if for some reason we still have header row
    next if ( login == 'Login')

    # Next if root
    next if ( login == 'root')

    describe "SELinux login #{login}" do
      # This is required by the STIG
      if login == '__default__'
        let(:valid_users){[ 'user_u' ]}
      elsif login == 'system_u'
        let(:valid_users){[ 'system_u' ]}
      elsif admin_logins.include?(login)
        let(:valid_users){[
          'sysadm_u',
          'staff_u'
        ]}
      else
        let(:valid_users){[
          'user_u',
          'guest_u',
          'xguest_u'
        ]}
      end
      it { expect(seuser).to be_in(valid_users) }
    end if selogin_context_enforcement.eql?('enabled')
    
    describe "The system is not eforcing Linux User <--> SELinux user mapping" do
      skip "The system is not eforcing Linux User <--> SELinux user mapping based on the 'selogin_context_enforcement' setting"
    end if !selogin_context_enforcement.eql?('enabled')
  end
end

# vim: set expandtab:ts=2:sw=2
