
package convolution_pkg IS
    type integer_vector is array(integer range <>) OF integer;
    type kernel_type is array(integer range <>, integer range <>) of integer;
    type img_type is array(integer range <>, integer range <>) of integer;
    
    constant img_dim: integer := 128; -- dimensions of input image, assuming square shape
    constant kernel_dim: integer := 5; -- dimensions of kernel, assuming square shape
    constant padding_dim: integer := img_dim + kernel_dim  - 1; --padded image dimensions, with as many padding layers as necessary
    constant input_file_path: string := "D:\0-EIT\KTH\P1\RM\implementation\repo\ImageRawArrayHex.txt";
    constant output_file_path: string := "D:\0-EIT\KTH\P1\RM\implementation\repo\outArrayHex.txt";
    constant padding_size: integer := (padding_dim - img_dim) / 2;
    constant padded_laplacian_size: integer:= 16899;
    constant padded_dog_size: integer := 17423;
    constant laplacian_kernel: kernel_type (0 to 2, 0 to 2) := ( 
            (0, 1, 0),
           (1, -4, 1),
            (0, 1, 0));
    constant dog_kernel: kernel_type (0 to 4, 0 to 4) := (
            (10, 11, 11, 11, 10),
            (11, 8, -11, 8, 11),
            (11, -11, -157, -11, 11),
            (11, 8, -11, 8, 11),
            (10, 11, 11, 11, 10));
end;