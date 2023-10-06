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

  /// @notice Verifies that the prover knows matrix * s = o.
  /// @param matrix The matrix
  /// @param s The solution vector
  /// @param o The output vector
  /// @return verified True if the prover knows matrix * s = o
  function matmul_nbyn(
    uint256[] calldata matrix,
    uint256 n, // n x n for the matrix
    ECPoint[] calldata s, // n elements
    uint256[] calldata o // n elements
  ) public view returns (bool verified) {
    // revert if dimensions don't make sense or the matrices are empty
    require(matrix.length == n ** 2, "Matrix matrix must be of n^2 length.");
    require(s.length == n, "Matrix s must be of n length.");
    require(o.length == n, "Matrix o must be of n length.");

    // return true if Ms == 0 elementwise. You need to do n equality checks. If you're lazy, you can hardcode n to 3, but it is suggested that you do this with a for loop

    // convert o to ECPoints
    ECPoint[] memory oPoints = new ECPoint[](o.length);

    for (uint i = 0; i < o.length; i++) {
      (uint256 pointX, uint256 pointY) = mul(o[i], G.x, G.y);
      oPoints[i] = ECPoint(pointX, pointY);
    }

    // verify
    ECPoint[] memory LHS = new ECPoint[](n);

    for (uint i = 0; i < n**2; i += n) {
      ECPoint[] memory accumulator = new ECPoint[](n);

      // Get scaled points
      for (uint j = 0; j < n; j++) {
        (uint256 pointX, uint256 pointY) = mul(matrix[j + i], s[j].x, s[j].y);
        accumulator[j] = ECPoint(pointX, pointY);
      }

      // Add scaled points together
      for (uint j = 0; j < n - 1; j++) {
        (uint256 pointX, uint256 pointY) = add(accumulator[j].x, accumulator[j].y, accumulator[j + 1].x, accumulator[j + 1].y);
        accumulator[j + 1] = ECPoint(pointX, pointY);
      }

      // Insert added points into LHS
      LHS[i / n] = accumulator[n - 1];
    }

    verified = true;

    for (uint i = 0; i < n; i++) {
      if (LHS[i].x != oPoints[i].x || LHS[i].y != oPoints[i].y) {
        verified = false;
        break;
      }
    }

    return verified;
  }
}
