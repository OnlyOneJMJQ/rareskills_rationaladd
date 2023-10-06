#!/bin/bash

function deploy() {
  forge create --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 ZK
}

# Test Case: 1/2 + 5/2 = 3/1
function test_rationalAdd() {
  cast send --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --rpc-url http://127.0.0.1:8545 0xA51c1fc2f0D1a1b8494Ed1FE312d7C3a78Ed91C0 "rationalAdd((uint256,uint256),(uint256,uint256),uint256,uint256)(bool)" "(10296210423881459776936787717049993391325552021605413991699412493845789633013,16532533273964472383651167452754510965928658867757334670578445799571582196663)" "(19032580475487806326057692075690361508625732333378927815997075982203596960703,8731032473663224878408972807329716494736032188868213550913069617079965841757)" 3 1
}

# Test Case: 1/3 + 5/17 = 32/51
function test_rationalAdd_brutal() {
  cast send --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --rpc-url http://127.0.0.1:8545 0xA51c1fc2f0D1a1b8494Ed1FE312d7C3a78Ed91C0 "rationalAdd((uint256,uint256),(uint256,uint256),uint256,uint256)(bool)" "(7882810270164319787005206832833610930431987920385435807716318376542052354560,19432520343525233641062008984286830060574134258521690491420158809041132350596)" "(1893605303548843236882693821488675454783355617924500803013052618837200072572,297461610705396111198119190839735034439455529249955383133560737578468227923)" 32 51
}

# Test Case: [1, 1, 1, 2, 2, 2, 3, 3, 3] * [1, 2, 1] = [4, 8, 12]
function test_matmul() {
  cast send --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --rpc-url http://127.0.0.1:8545 0x0DCd1Bf9A1b36cE34237eEaFef220932846BCD82 "matmul_nbyn(uint256[],uint256,(uint256,uint256)[],uint256[])(bool)" "[1,1,1,2,2,2,3,3,3]" 3 "[(3010198690406615200373504922352659861758983907867017329644089018310584441462,4027184618003122424972590350825261965929648733675738730716654005365300998076),(3932705576657793550893430333273221375907985235130430286685735064194643946083,18813763293032256545937756946359266117037834559191913266454084342712532869153),(17108685722251241369314020928988529881027530433467445791267465866135602972753,20666112440056908034039013737427066139426903072479162670940363761207457724060)]" "[4,8,12]"
}

# Scratchpad for testing in Remix
# [1,1,1,2,2,2,3,3,3]
# 3
# [[1,2],[1368015179489954701390400359078579693043519447331113978918064868415326638035,9918110051302171585080402603319702774565515993150576347155970296011118125764],[1,2]]
# [4,8,12]