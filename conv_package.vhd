
package convolution_pkg IS
    type integer_vector is array(integer range <>) OF integer;
    type kernel_type is array(integer range <>, integer range <>) of integer;
    type img_type is array(integer range <>, integer range <>) of integer; 
end;