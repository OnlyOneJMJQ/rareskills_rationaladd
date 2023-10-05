// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract ZK {
    struct ECPoint {
        uint256 x;
        uint256 y;
    }

    uint256 order = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    ECPoint G = ECPoint(1, 2);

    function add(uint256 x1, uint256 y1, uint256 x2, uint256 y2) public view returns (uint256 x, uint256 y) {
        (bool ok, bytes memory result) = address(6).staticcall(abi.encode(x1, y1, x2, y2));
        require(ok, "add failed");
        (x, y) = abi.decode(result, (uint256, uint256));
    }

    function mul(uint256 scalar, uint256 x1, uint256 y1) public view returns (uint256 x, uint256 y) {
        (bool ok, bytes memory result) = address(7).staticcall(abi.encode(x1, y1, scalar));
        require(ok, "mul failed");
        (x, y) = abi.decode(result, (uint256, uint256));
    }

    // Example Cases:
    // 1/3 + 5/17 = 32/51
    // 17/51 + 15/51 = 32/51
    // A: ["7882810270164319787005206832833610930431987920385435807716318376542052354560", "19432520343525233641062008984286830060574134258521690491420158809041132350596"]
    // B: ["1893605303548843236882693821488675454783355617924500803013052618837200072572", "297461610705396111198119190839735034439455529249955383133560737578468227923"]
    //
    // 1/2 + 5/2 = 3/1
    // A: ["10296210423881459776936787717049993391325552021605413991699412493845789633013", "16532533273964472383651167452754510965928658867757334670578445799571582196663"]
    // B: ["19032580475487806326057692075690361508625732333378927815997075982203596960703", "8731032473663224878408972807329716494736032188868213550913069617079965841757"]
    function rationalAdd(ECPoint calldata A, ECPoint calldata B, uint256 num, uint256 den) public view returns (bool verified) {
        require(den != 0, "Denominator cannot be zero.");
        
        // return true if the prover knows two numbers that add up to num/den
        (uint LHSx, uint LHSy) = add(A.x, A.y, B.x, B.y);
        (LHSx, LHSy) = mul(1*10**16, LHSx, LHSy);
        uint256 inter = 1*10**16 / den;
        uint256 rhs = (num * (inter % order)) % order;
        // return a*(10**precision)/b;
        (uint RHSx, uint RHSy) = mul(rhs, G.x, G.y);
    
        verified = LHSx == RHSx && LHSy == RHSy;

        return verified;

        // num_over_den = (num * pow(den, -1, curve_order)) % curve_order
        // return multiply(G1, num_over_den)
    }

    // Example Case:
    // [1, 1, 1, 2, 2, 2, 3, 3, 3] x [1, 2, 1] = [4, 8, 12]
    function matmul_nbyn(
        uint256[] calldata matrix,
        uint256 n, // n x n for the matrix
        ECPoint[] calldata s, // n elements
        ECPoint[] calldata o // n elements
    ) public view returns (bool verified) {
        // revert if dimensions don't make sense or the matrices are empty
        // TODO: Improve these requirement checks
        require(s.length > 0, "Matrix s must not be empty.");
        require(o.length > 0, "Matrix o must not be empty.");
        require(s.length == o.length, "Matrices must be of equal size.");

        // return true if Ms == 0 elementwise. You need to do n equality checks. If you're lazy, you can hardcode n to 3, but it is suggested that you do this with a for loop
        
        // ECPoint[3] memory s = [
        //     ECPoint(3010198690406615200373504922352659861758983907867017329644089018310584441462, 4027184618003122424972590350825261965929648733675738730716654005365300998076),
        //     ECPoint(3932705576657793550893430333273221375907985235130430286685735064194643946083, 18813763293032256545937756946359266117037834559191913266454084342712532869153),
        //     ECPoint(17108685722251241369314020928988529881027530433467445791267465866135602972753, 20666112440056908034039013737427066139426903072479162670940363761207457724060)
        // ];

        // ECPoint[3] memory o = [
        //     ECPoint(1, 2),
        //     ECPoint(1368015179489954701390400359078579693043519447331113978918064868415326638035, 9918110051302171585080402603319702774565515993150576347155970296011118125764),
        //     ECPoint(1, 2)
        // ];
    
        // Had to use nasty pattern because of call depth
        // I <3 Solidity
        for (uint i = 0; i < n; i++) {
            // Mulitply M by points in o
            (uint256 oneone_x, uint256 oneone_y) = mul(matrix[0 + i * n], o[i].x, o[i].y);
            (uint256 twoone_x, uint256 twoone_y) = mul(matrix[1 + i * n], o[i].x, o[i].y);
            (uint256 threeone_x, uint256 threeone_y) = mul(matrix[2 + i * n], o[i].x, o[i].y);

            // Add points together to get point for testing against s
            (uint256 firstadd_x, uint256 firstadd_y) = add(oneone_x, oneone_y, twoone_x, twoone_y);
            (uint256 secondadd_x, uint256 secondadd_y) = add(firstadd_x, firstadd_y, threeone_x, threeone_y);

            // If the points are unequal, we break and return false.
            // No need to continue processing.
            if (secondadd_x != s[0].x || secondadd_y != s[0].y) {
                return false;
            }
        }

        return true;
    }
}


// s = [["3010198690406615200373504922352659861758983907867017329644089018310584441462", "4027184618003122424972590350825261965929648733675738730716654005365300998076"],["3932705576657793550893430333273221375907985235130430286685735064194643946083", "18813763293032256545937756946359266117037834559191913266454084342712532869153"],["17108685722251241369314020928988529881027530433467445791267465866135602972753", "20666112440056908034039013737427066139426903072479162670940363761207457724060"]]

// o = [["1", "2"],["1368015179489954701390400359078579693043519447331113978918064868415326638035", "9918110051302171585080402603319702774565515993150576347155970296011118125764"],["1", "2"]]
