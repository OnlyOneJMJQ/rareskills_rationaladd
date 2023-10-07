// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/ZK.sol";

contract ContractBTest is Test {

    ZK zk;
    uint256 order = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    ZK.ECPoint G = ZK.ECPoint(1, 2);

    function setUp() public {
        zk = new ZK();
    }

    function test_easy_rational() public {
        // 1/2 + 5/2 = 3/1
        ZK.ECPoint memory A = ZK.ECPoint(
           10296210423881459776936787717049993391325552021605413991699412493845789633013,
           16532533273964472383651167452754510965928658867757334670578445799571582196663 
        );

        ZK.ECPoint memory B = ZK.ECPoint(
            19032580475487806326057692075690361508625732333378927815997075982203596960703,
            8731032473663224878408972807329716494736032188868213550913069617079965841757
        );

        bool verified = zk.rationalAdd(A, B, 3, 1);
        assertEq(verified, true);
    }

    function test_brutal_rational() public {
        // 1/3 + 5/17 = 32/51
        ZK.ECPoint memory A = ZK.ECPoint(
          7882810270164319787005206832833610930431987920385435807716318376542052354560,
          19432520343525233641062008984286830060574134258521690491420158809041132350596 
        );

        ZK.ECPoint memory B = ZK.ECPoint(
          1893605303548843236882693821488675454783355617924500803013052618837200072572,
          297461610705396111198119190839735034439455529249955383133560737578468227923 
        );

        bool verified = zk.rationalAdd(A, B, 32, 51);
        assertTrue(verified, "oops, rational addition failed");
    }


    function test_matrix_multiply() public {
        // # Test Case: [1, 1, 1, 2, 2, 2, 3, 3, 3] * [1, 2, 1] = [4, 8, 12]
        uint256 n = 3;

        uint256[] memory matrix = new uint256[](9);
        matrix[0] = 1; matrix[1] = 1; matrix[2] = 1;
        matrix[3] = 2; matrix[4] = 2; matrix[5] = 2;
        matrix[6] = 3; matrix[7] = 3; matrix[8] = 3;

        ZK.ECPoint[] memory s = new ZK.ECPoint[](3);
        s[0] = ZK.ECPoint(
            1,
            2
        );
        s[1] = ZK.ECPoint(

            1368015179489954701390400359078579693043519447331113978918064868415326638035,
            9918110051302171585080402603319702774565515993150576347155970296011118125764
        );    
        s[2] = ZK.ECPoint(
            1,
            2
        );

        uint256[] memory o = new uint256[](3);
        o[0] = 4; o[1] = 8; o[2] = 12;

        bool verified = zk.matmul_nbyn(matrix, n, s, o);
        assertTrue(verified, "oops, matrix multiplication failed");
    }
}
