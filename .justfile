# A configuration file for `just`, a command runner and successor to `make`
# https://github.com/casey/just/tree/master
#
# examples:
# https://github.com/casey/just/blob/master/examples/pre-commit.just
# https://github.com/casey/just/blob/master/examples/kitchen-sink.just

# ignore comments in the command area
set ignore-comments := true 

# load .env vars
# set dotenv-load := true 

# set custom env vars
export RUST_LOG := "info"
# export RUST_BACKTRACE := "1"


@just:
    just --list

# install js dependencies and circom
install:
    npm install

test: 
    npx mocha

testg testname:
    npx mocha -g {{testname}}

# # You can test that the witnesses in `inputs` are valid by using 
# # the `build/**/generate_witness.js` circom artifact. 
# # generate witnesses and run the `generate_witness.js` script:
# witness:
#     mkdir build

#     # generate the `wtns` file from the json witnesses generated in rust
#     # also checks that the json witness has the right number of bytes
#     # and the json keys match the circom `signal` inputs
#     node build/gcm_siv_dec_2_keys_test_js/generate_witness.js build/gcm_siv_dec_2_keys_test_js/gcm_siv_dec_2_keys_test.wasm inputs/witness.json build/witness.wtns

