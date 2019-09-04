#
# Enter the name of the key pair you want to use (we can't provide it to you)
#
echo -n "Please enter the name of the key pair you wish to use: " &&
read KEY_PAIR &&
echo "
  key_pair      = \"$KEY_PAIR\"
" >>terraform.tfvars
