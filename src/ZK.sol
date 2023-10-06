// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract ZK {
  struct ECPoint {
    uint256 x;
    uint256 y;
  }

  uint256 order = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
  ECPoint G = ECPoint(1, 2);

  /// @dev Adds two EC points together and returns the resulting point.
  /// @param x1 The x coordinate of the first point
  /// @param y1 The y coordinate of the first point
  /// @param x2 The x coordinate of the second point
  /// @param y2 The y coordinate of the second point
  /// @return x The x coordinate of the resulting point
  /// @return y The y coordinate of the resulting point
  function add(uint256 x1, uint256 y1, uint256 x2, uint256 y2) internal view returns (uint256 x, uint256 y) {
    (bool ok, bytes memory result) = address(6).staticcall(abi.encode(x1, y1, x2, y2));
    require(ok, "add failed");
    (x, y) = abi.decode(result, (uint256, uint256));
  }

  /// @dev Multiplies an EC point by a scalar and returns the resulting point.
  /// @param scalar The scalar to multiply by
  /// @param x1 The x coordinate of the point
  /// @param y1 The y coordinate of the point
  /// @return x The x coordinate of the resulting point
  /// @return y The y coordinate of the resulting point
  function mul(uint256 scalar, uint256 x1, uint256 y1) internal view returns (uint256 x, uint256 y) {
    (bool ok, bytes memory result) = address(7).staticcall(abi.encode(x1, y1, scalar));
    require(ok, "mul failed");
    (x, y) = abi.decode(result, (uint256, uint256));
  }

  /// @dev Modular euclidean inverse of a number (mod p).
  /// @param _x The number
  /// @param _pp The modulus
  /// @return q such that x*q = 1 (mod _pp)
  function invMod(uint256 _x, uint256 _pp) internal pure returns (uint256) {
    require(_x != 0 && _x != _pp && _pp != 0, "Invalid number");
    uint256 q = 0;
    uint256 newT = 1;
    uint256 r = _pp;
    uint256 t;
    while (_x != 0) {
      t = r / _x;
      (q, newT) = (newT, addmod(q, (_pp - mulmod(t, newT, _pp)), _pp));
      (r, _x) = (_x, r - t * _x);
    }

    return q;
  }
  
  /// @notice Verifies that the prover knows two numbers that add up to num/den.
  /// @param A The first point
  /// @param B The second point
  /// @param num The numerator
  /// @param den The denominator
  /// @return verified True if the prover knows two numbers that add up to num/den
  function rationalAdd(ECPoint calldata A, ECPoint calldata B, uint256 num, uint256 den) public view returns (bool verified) {
    require(den != 0, "Denominator cannot be zero.");
    
    // return true if the prover knows two numbers that add up to num/den
    (uint LHSx, uint LHSy) = add(A.x, A.y, B.x, B.y);
    uint256 rhs = mulmod(num, invMod(den, order), order);
    (uint RHSx, uint RHSy) = mul(rhs, G.x, G.y);
  
    verified = LHSx == RHSx && LHSy == RHSy;

    return verified;
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
    //   ECPoint(3010198690406615200373504922352659861758983907867017329644089018310584441462, 4027184618003122424972590350825261965929648733675738730716654005365300998076),
    //   ECPoint(3932705576657793550893430333273221375907985235130430286685735064194643946083, 18813763293032256545937756946359266117037834559191913266454084342712532869153),
    //   ECPoint(17108685722251241369314020928988529881027530433467445791267465866135602972753, 20666112440056908034039013737427066139426903072479162670940363761207457724060)
    // ];

    // ECPoint[3] memory o = [
    //   ECPoint(1, 2),
    //   ECPoint(1368015179489954701390400359078579693043519447331113978918064868415326638035, 9918110051302171585080402603319702774565515993150576347155970296011118125764),
    //   ECPoint(1, 2)
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
