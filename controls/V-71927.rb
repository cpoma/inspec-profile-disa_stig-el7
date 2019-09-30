# encoding: utf-8
#
known_exception_accounts = attribute(
  'known_exception_accounts',
  description: 'Accounts that granted policy exceptions (Array)',
  value: ['root']
)

control "V-71927" do
  title "Passwords must be restricted to a 24 hours/1 day minimum lifetime."
  desc  "Enforcing a minimum password lifetime helps to prevent repeated
password changes to defeat the password reuse or history enforcement
requirement. If users are allowed to immediately and continually change their
password, the password could be repeatedly changed in a short period of time to
defeat the organization's policy regarding password reuse."
  impact 0.5
  tag "gtitle": "SRG-OS-000075-GPOS-00043"
  tag "gid": "V-71927"
  tag "rid": "SV-86551r1_rule"
  tag "stig_id": "RHEL-07-010240"
  tag "cci": ["CCI-000198"]
  tag "documentable": false
  tag "nist": ["IA-5 (1) (d)", "Rev_4"]
  tag "subsystems": ['password', '/etc/shadow']
  tag "check": "Check whether the minimum time period between password changes
for each user account is one day or greater.

# awk -F: '$4 < 1 {print $1}' /etc/shadow

If any results are returned that are not associated with a system account, this
is a finding."
  tag "fix": "Configure non-compliant accounts to enforce a 24 hours/1 day
minimum password lifetime:

# chage -m 1 [user]"
  tag "fix_id": "F-78279r1_fix"

  test_run = false
  shadow.users.each do |user|
    # filtering on non-system accounts (uid >= 1000)
    if !user.nil? && !user(user).uid.nil?
      next unless user(user).uid >= 1000
      if !known_exception_accounts.nil?
        next if known_exception_accounts.include?("#{user}")
      end
      test_run = true
      describe shadow.users(user) do
        its('min_days.first.to_i') { should cmp >= 1 }
      end
    end
  end

  if !test_run
    describe "This control skipped. No users found to test. All skipped based on 'known_exception_accounts' settings or UID >= 1000" do
      skip "This control skipped. No users found to test. All skipped based on 'known_exception_accounts' settings or UID >= 1000"
    end
  end
end

