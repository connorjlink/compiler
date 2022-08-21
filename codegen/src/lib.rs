mod bindings;
mod driver;
mod error;
mod expression;
mod statement;
mod util;

use bindings::*;
use error::*;
use driver::*;
use statement::*;
use util::*;




fn generate_function(driver: &mut Driver, function: *const Function)
{
    unsafe
    {
        let fname = convert_string((*function).name);
        let fdefined = !(*function).body.is_null();

        driver.add_to_symbol_table(Symbol{ name: fname, defined: fdefined, symbol_type: SymbolType::FUNCTION });

        driver.add_to_code(format!("@function_start_{}:", fname));

        if fdefined
        {
            generate_statement(driver, (*function).body, function);
        }

        driver.add_to_code("pop IP".to_string());
    }
}


//will be called by the C frontend
//basically main()
#[no_mangle]
pub extern "C" fn generate(program: *const Program, parameters: *const Parameters)
{
    let mut driver = Driver{ symbol_table: vec![], code_segment: "".to_string(), available_registers: R0 | R1 | R2 | R3, counter: 0 };

    driver.add_to_code(".begin\n".to_string());
    driver.add_to_code(".include \"def.s\"\n".to_string());


    let found_main = false;

    unsafe
    {
        for i in 0..(*program).num_functions
        {
            let fun = (*program).functions.offset(i.into());

            generate_function(&mut driver, fun);

            if convert_string((*fun).name) == "main"
            {
                found_main = true;
            }
        }
    }



    if !found_main
    {
        codegen_error("No function 'main' was defined.".to_owned());
    }

    driver.add_to_code(".end".to_string());
}

