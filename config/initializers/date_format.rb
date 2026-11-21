Date::DATE_FORMATS[:default] = "%d-%m-%Y"

# Up to Rails 7.0, Date#to_s used DATE_FORMATS[:default], so dates rendered
# in views ("<%= txn.on_date %>") and string interpolation came out as
# dd-mm-yyyy. Rails 7.1+ dropped that and Date#to_s returns ISO yyyy-mm-dd.
# Restore the old behaviour so the upgrade doesn't change what users see.
# Active Record quoting, JSON and date_field use to_fs(:db)/strftime, so
# they are unaffected. DateTime defines its own #to_s and is unaffected too.
module LegacyDateToS
  def to_s
    Date::DATE_FORMATS.key?(:default) ? to_fs(:default) : super
  end
end

Date.prepend(LegacyDateToS)
