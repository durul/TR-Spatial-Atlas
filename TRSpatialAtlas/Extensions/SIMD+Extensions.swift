//
//  SIMD+Extensions.swift
//  TRSpatialAtlas
//
//  Created by durul dalkanat on 1/30/26.
//

import simd

// MARK: - simd_float4x4 Extensions

/// 3D transform = 4x4.
/// Extension to extract position and rotation from a 4x4 transformation matrix.
/// Useful for ARKit device anchors and entity transforms.
extension simd_float4x4 {
    // MARK: Position 📍

    /// Extracts the translation (position) from the 4x4 matrix.
    /// The position is stored in the 4th column (columns.3) of the matrix.
    /// columns.3 → The device's position in the world (translation)
    var position: SIMD3<Float> {
        SIMD3<Float>(columns.3.x, columns.3.y, columns.3.z)
    }

    // MARK: rotation (quaternion rotation) 🌀

    /// Extracts the rotation as a quaternion from the 4x4 matrix.
    /// This handles scale extraction and determinant sign correction.
    var rotation: simd_quatf {
        // Extract rotation axes from the matrix
        let x = simd_float3(columns.0.x, columns.0.y, columns.0.z)
        let y = simd_float3(columns.1.x, columns.1.y, columns.1.z)
        let z = simd_float3(columns.2.x, columns.2.y, columns.2.z)

        // Calculate scale factors to normalize the rotation
        let scaleX = simd_length(x)
        let scaleY = simd_length(y)
        let scaleZ = simd_length(z)

        // Calculate determinant sign to handle reflection matrices
        let sign = simd_sign(
            columns.0.x * columns.1.y * columns.2.z +
                columns.0.y * columns.1.z * columns.2.x +
                columns.0.z * columns.1.x * columns.2.y -
                columns.0.z * columns.1.y * columns.2.x -
                columns.0.y * columns.1.x * columns.2.z -
                columns.0.x * columns.1.z * columns.2.y
        )

        // Create normalized rotation matrix
        let rotationMatrix = simd_float3x3(x / scaleX, y / scaleY, z / scaleZ)

        // Creates a simd_float3x3 matrix and converts it to a quaternion using simd_quaternion(...)
        let quaternion = simd_quaternion(rotationMatrix)

        // Checks for reflection (mirroring/inversion) using a determinant-like calculation and corrects the sign accordingly.
        return sign >= 0 ? quaternion : -quaternion
    }

    /// Extracts the forward direction vector (negative Z axis) from the matrix.
    /// Useful for determining which way an entity or device is facing.
    var forward: SIMD3<Float> {
        -SIMD3<Float>(columns.2.x, columns.2.y, columns.2.z)
    }

    /// Extracts the horizontal forward direction (Y component zeroed).
    /// Useful for ground-parallel movement calculations.
    var horizontalForward: SIMD3<Float> {
        let forward = SIMD3<Float>(-columns.2.x, 0, -columns.2.z)
        return simd_length(forward) > 0 ? simd_normalize(forward) : SIMD3<Float>(0, 0, -1)
    }
}
