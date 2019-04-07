__precompile__()

module Utils

    export @define, @reexport, @dec128

    include("utils/macro_utils.jl")

    export compensated_summation
    export istriustrict, istrilstrict, L2norm, l2norm
    export simd_copy_xy_first!, simd_copy_yx_first!, simd_copy_yx_second!,
           simd_copy_yx_first_last!,
           simd_axpy!, simd_aXbpy!, simd_abXpy!, simd_mult!

    include("utils/matrix_utils.jl")

end
