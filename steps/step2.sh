#
# Make sure "aws configure" has applied good credentials
# We hide the output here since it contains the 
# access key and account id.
#
aws sts get-caller-identity >/dev/null 2>&1 &&
echo "Success!" ||
(echo "Failure!"; false)
