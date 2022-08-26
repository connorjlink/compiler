#include "Expression.hpp"

#include "Context.hpp"
#include "Function.hpp"
#include "Error.hpp"
#include "Driver.hpp"

#include <stdexcept>
#include <exception>

namespace
{
    bool funcs_equal(ti::Function& f1, ti::Function& f2)
    {
        return (f1.name                  == f2.name)                  &&
               (f1.arguments             == f2.arguments)             &&
               (f1.body                  == f2.body)                  &&
               (f1.return_type.specifier == f2.return_type.specifier) &&
               (f1.return_type.qualifier == f2.return_type.qualifier);
    }
}




void ti::expr::Stringconst::generate(ti::Context& context, ti::Function& function, const ti::ForcedAllocation& allocation) noexcept
{
    
}

void ti::expr::Identifier::generate(ti::Context& context, ti::Function& function, const ti::ForcedAllocation& allocation) noexcept
{
    const auto loc = std::find_if(context.symbol_table.begin(), context.symbol_table.end(), [&](Symbol* s)
    {
        return (name == s->name);
    });
    
    if (loc == std::end(context.symbol_table))
    {
        ti::throw_error("Identifier %s is previously undefined", name.c_str());
    }
    if (!((*loc)->defined))
    {
        ti::throw_error("Identifier %s was not previously assigned a valid value", name.c_str());
    }
    if ((*loc)->type == ti::SymbolType::FUNCTION)
    {
        ti::throw_error("Identifier %s was previously defined as a function", name.c_str());
    }
    else
    {
        //symbol seems valid and of type variable
        auto nsym = static_cast<ti::VariableSymbol*>(*loc);
        
        if (nsym->visibility == ti::TypeVisibility::LOCAL                          &&
           (nsym->function.name                  != function.name                  ||
            nsym->function.arguments             != function.arguments             ||
            nsym->function.body                  != function.body                  ||
            nsym->function.return_type.specifier != function.return_type.specifier ||
            nsym->function.return_type.qualifier != function.return_type.qualifier))
        {
            //variable is local to a different function
            ti::throw_error("Identifier %s is inaccessible from function %s", name.c_str(), function.name.c_str());
        }
        
        //variable is good to query and load
        context.add_to_code(ti::format("ldb %s, %%%u\n", ti::location_to_string(allocation.location).c_str(), nsym->address));
    }
}

void ti::expr::Ternary::generate(ti::Context& context, ti::Function& function, const ti::ForcedAllocation& allocation) noexcept
{
    left->generate(context, function, allocation);
    
    context.add_to_code("updateFlags()\n");
    
    const auto label_template = "ternary_%s_%s_%u";
    
    
    const auto end_label = ti::format(label_template, "end", function.name.c_str(), context.counter);
    context.add_to_code(ti::format("jez [%s]\n", end_label.c_str()).c_str());
    
    context.add_to_code(ti::format("@%s:\n", ti::format(label_template, "first", function.name.c_str(), context.counter).c_str()));
    
    center->generate(context, function, allocation);
    context.add_to_code(ti::format("jmp([%s])\n", end_label.c_str()).c_str());
    
    context.add_to_code(ti::format("@%s:\n", ti::format(label_template, "second", function.name.c_str(), context.counter).c_str()));
    
    right->generate(context, function, allocation);
    context.add_to_code(ti::format("jmp([%s])\n", end_label.c_str()).c_str());
    
    context.add_to_code(ti::format("@%s:\n", end_label.c_str()).c_str());
}



/*--------------------------------*
 | NUMCONST EXPRESSION GENERATION |
 *--------------------------------*/

void ti::expr::num::Numconst8::generate(ti::Context& context, ti::Function& function, const ti::ForcedAllocation& allocation) noexcept
{
    ti::write_log("Generating code for 8-bit numeric constant expression");
    
    context.add_to_code(ti::format("ldb %s, #%u\n", ti::location_to_string(allocation.location).c_str(), value));
}



/*------------------------------*
 | BINARY EXPRESSION GENERATION |
 *------------------------------*/

void ti::expr::binary::Index::generate(ti::Context& context, ti::Function& function, const ti::ForcedAllocation& allocation) noexcept
{
    ti::write_log("Generating code for array index expression");
}

void ti::expr::binary::FCall::generate(ti::Context& context, ti::Function& function, const ti::ForcedAllocation& allocation) noexcept
{
    ti::write_log("Generating code for function call expression");
}


void ti::expr::binary::Equals::generate(ti::Context& context, ti::Function& function, const ti::ForcedAllocation& allocation) noexcept
{
    ti::write_log("Generating code for binary assignment expression");
    
    if (left->type != ti::ExpressionType::IDENTIFIER)
    {
        ti::throw_error("Left side of assignment is not an identifier");
    }
    
    auto* ident = static_cast<ti::expr::Identifier*>(left);
    
    const auto loc = std::find_if(context.symbol_table.begin(), context.symbol_table.end(), [&](Symbol* s)
    {
        return (ident->name == s->name);
    });
    
    
    if (loc == std::end(context.symbol_table))
    {
        ti::throw_error("Identifier %s is previously undefined", ident->name.c_str());
    }
    if (!((*loc)->defined))
    {
        ti::throw_error("Identifier %s was not previously assigned a valid value", ident->name.c_str());
    }
    if ((*loc)->type == ti::SymbolType::FUNCTION)
    {
        ti::throw_error("Identifier %s was previously defined as a function", ident->name.c_str());
    }
    else
    {
        //symbol seems valid and of type variable
        auto nsym = static_cast<ti::VariableSymbol*>(*loc);
        
        if (nsym->visibility == ti::TypeVisibility::LOCAL                          &&
           (nsym->function.name                  != function.name                  ||
            nsym->function.arguments             != function.arguments             ||
            nsym->function.body                  != function.body                  ||
            nsym->function.return_type.specifier != function.return_type.specifier ||
            nsym->function.return_type.qualifier != function.return_type.qualifier))
        {
            //variable is local to a different function
            ti::throw_error("Identifier %s is inaccessible from function %s", ident->name.c_str(), function.name.c_str());
        }
        
        right->generate(context, function, allocation);
        context.add_to_code("stb %%%u, %s\n", nsym->address, )
    }
}

void ti::expr::binary::Plus::generate(ti::Context& context, ti::Function& function, const ti::ForcedAllocation& allocation) noexcept
{
    ti::write_log("Generating code for binary addition expression");
}

void ti::expr::binary::Minus::generate(ti::Context& context, ti::Function& function, const ti::ForcedAllocation& allocation) noexcept
{
    ti::write_log("Generating code for binary subtraction expression");
}

void ti::expr::binary::PlusEquals::generate(ti::Context& context, ti::Function& function, const ti::ForcedAllocation& allocation) noexcept
{
    ti::write_log("Generating code for binary assignment-addition expression");
}

void ti::expr::binary::MinusEquals::generate(ti::Context& context, ti::Function& function, const ti::ForcedAllocation& allocation) noexcept
{
    ti::write_log("Generating code for binary assignment-subtraction expression");
}

void ti::expr::binary::LeftShift::generate(ti::Context& context, ti::Function& function, const ti::ForcedAllocation& allocation) noexcept
{
    ti::write_log("Generating code for binary left shift expression");
}

void ti::expr::binary::RightShift::generate(ti::Context& context, ti::Function& function, const ti::ForcedAllocation& allocation) noexcept
{
    ti::write_log("Generating code for binary right shift expression");
}

void ti::expr::binary::BitXor::generate(ti::Context& context, ti::Function& function, const ti::ForcedAllocation& allocation) noexcept
{
    ti::write_log("Generating code for binary bitwise xor expression");
}

void ti::expr::binary::BitAnd::generate(ti::Context& context, ti::Function& function, const ti::ForcedAllocation& allocation) noexcept
{
    ti::write_log("Generating code for binary bitwise and expression");
}

void ti::expr::binary::BitOr::generate(ti::Context& context, ti::Function& function, const ti::ForcedAllocation& allocation) noexcept
{
    ti::write_log("Generating code for binary bitwise or expression");
}

void ti::expr::binary::LogAnd::generate(ti::Context& context, ti::Function& function, const ti::ForcedAllocation& allocation) noexcept
{
    ti::write_log("Generating code for binary logical and expression");
}

void ti::expr::binary::LogOr::generate(ti::Context& context, ti::Function& function, const ti::ForcedAllocation& allocation) noexcept
{
    ti::write_log("Generating code for binary logical or expression");
}

void ti::expr::binary::EqualsEquals::generate(ti::Context& context, ti::Function& function, const ti::ForcedAllocation& allocation) noexcept
{
    ti::write_log("Generating code for binary equals-equals expression");
}

void ti::expr::binary::NotEquals::generate(ti::Context& context, ti::Function& function, const ti::ForcedAllocation& allocation) noexcept
{
    ti::write_log("Generating code for binary not-equals expression");
}

void ti::expr::binary::Less::generate(ti::Context& context, ti::Function& function, const ti::ForcedAllocation& allocation) noexcept
{
    ti::write_log("Generating code for binary less expression");
}

void ti::expr::binary::LessEquals::generate(ti::Context& context, ti::Function& function, const ti::ForcedAllocation& allocation) noexcept
{
    ti::write_log("Generating code for binary less-equals expression");
}

void ti::expr::binary::Greater::generate(ti::Context& context, ti::Function& function, const ti::ForcedAllocation& allocation) noexcept
{
    ti::write_log("Generating code for binary greater expression");
}

void ti::expr::binary::GreaterEquals::generate(ti::Context& context, ti::Function& function, const ti::ForcedAllocation& allocation) noexcept
{
    ti::write_log("Generating code for binary greater-equals expression");
}



/*-----------------------------*
 | UNARY EXPRESSION GENERATION |
 *-----------------------------*/

void ti::expr::unary::PlusPlus::generate(ti::Context& context, ti::Function& function, const ti::ForcedAllocation& allocation) noexcept
{
    ti::write_log("Generating code for increment unary expression");
    
    //return value allocation is free for use
    center->generate(context, function, allocation);
    
    context.add_to_code(ti::format("adc %s, #1\n", ti::location_to_string(allocation.location).c_str()));
}

void ti::expr::unary::MinusMinus::generate(ti::Context& context, ti::Function& function, const ti::ForcedAllocation& allocation) noexcept
{
    ti::write_log("Generating code for decrement unary expression");
    
    //return value allocation is free for use
    center->generate(context, function, allocation);
    
    context.add_to_code(ti::format("sbb %s, #1\n", ti::location_to_string(allocation.location).c_str()));
}

void ti::expr::unary::Addrof::generate(ti::Context& context, ti::Function& function, const ti::ForcedAllocation& allocation) noexcept
{
    ti::write_log("Generating code for address-of unary expression");
    
    ti::throw_error("Unary addressof is unsupported currently");
#warning UNIMPLEMENTED FUNCTION
}

void ti::expr::unary::Deref::generate(ti::Context& context, ti::Function& function, const ti::ForcedAllocation& allocation) noexcept
{
    ti::write_log("Generating code for dereference unary expression");
    
    ti::throw_error("Unary dereferencing is unsupported currently");
#warning UNIMPLEMENTED FUNCTION
}

void ti::expr::unary::Positive::generate(ti::Context& context, ti::Function& function, const ti::ForcedAllocation& allocation) noexcept
{
    ti::write_log("Generating code for nop (+) unary expression");
    
    //return value allocation is free for use
    center->generate(context, function, allocation);
}

void ti::expr::unary::Negative::generate(ti::Context& context, ti::Function& function, const ti::ForcedAllocation& allocation) noexcept
{
    ti::write_log("Generating code for negate unary expression");
    
    //return value allocation is free for use
    center->generate(context, function, allocation);
    
    const auto loc = ti::location_to_string(allocation.location);
    const auto reg = loc.c_str();
    
    context.add_to_code(ti::format("not %s\n", reg));
    context.add_to_code(ti::format("adc %s, #1\n", reg));
}
