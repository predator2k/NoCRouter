import noc_params::*;

interface router2router;

    flit_t data;
    logic is_valid;
    logic is_on_off;
    logic is_allocatable;

    modport upstream (
        output data,
        output is_valid,
        input is_on_off,
        input is_allocatable
    );

    modport downstream (
        input data,
        input is_valid,
        output is_on_off,
        output is_allocatable
    );

endinterface