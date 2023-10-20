create or replace package INSUM$DATA_PKG_UTIL as
--
-- set_testing_on
-- 
-- This procedure will set testing mode on. Testing mode only applies to constraints.
-- Testing mode does not affect identity column or sequence processing.
-- No constraints will be disabled or enabled when testing is on.
-- Instead, dbms_output will output the names of the constraints that would be disabled.
-- NOTE: Testing is enabled only within a session. This will not work across APEX page views or
--       across APEX Dynamic Actions. See the example below.
--
-- example:
--  begin
--      insum$data_pkg_util.set_testing_on;
--      insum$data_pkg_util.disable_constraints(
--          p_tables => apex_t_varchar2('emp','dept', 'product', 'order','order_line')
--       );
--  end;
procedure set_testing_on;
--
--
-- set_testing_off
--
-- This procedure will set testing off.
procedure set_testing_off;
--
--
--====================================================================================
-- disable_constraints
--
-- Disables any enabled constraints on the tables passed in via p_tables. The logged in 
-- user must have appropriate privileges on the tables defined by p_schema and p_tables. 
--
-- The names of any disabled constraints will be stored in a private package variable 
-- for use by the procedure enable_disabled_constraints. If you need to access it, 
-- call the disabled_constraints function.
--
-- Note: This procedure does NOT cascade constraints. Hence, you may need to pass
--       the list of tables in p_tables in a particular order.
-- 
-- p_tables: List of tables whose enabled constraints will be disabled and the names 
--      will be stored in g_disabled_constraints. Null indicates all table of 
--      p_schema (default CURRENT_USER).
-- p_preserve_case: FALSE indicates all table names provided in p_tables will be 
--      changed to upper case. TRUE indicates to use the case of the 
--      table names provided in p_tables.
-- p_constraint_type: Indicate the type ('R','C','P',...) of constraint that will be 
--      disabled. See Oracle documentation.                  
-- p_clear_disabled_constrainst_list: TRUE clear the disabled_constrainst_list  
--                                    FALSE do nothing
-- p_schema: Specifies the schema that owns the constraints that will be disabled 
--      By default, the program will use CURRENT_USER.
-- p_constraint_filter: uses to filter the constraints based on their name.(Ex.'BUI%',
--      '%S_C0015709%'). The contraint name and the filter are case sensitive.
--      If null, no filter will be applied.
-- 
-- examples:
--  begin
--      insum$data_pkg_util.disable_constraints(
--          p_constraint_type => 'R',  -- only referential (FK) constraints,
--          p_tables => apex_t_varchar2('emp','dept', 'product', 'order','order_line')
--       );
--  end;
--
--  begin
--      insum$data_pkg_util.disable_constraints(
--          p_constraint_type => 'R',  -- only referential (FK) constraints    
--          p_tables => apex_t_varchar2('emp','dept', 'product', 'order','order_line'),
--          p_preserve_case => false,
--          p_clear_disabled_constrainst_list => false,
--          p_schema => 'INTRACK',
--          p_constraint_filter ==> 'BUI%'
--       );
--  end;
--====================================================================================
procedure disable_constraints(
    p_constraint_type                 in user_constraints.constraint_name%type,
    p_tables                          in apex_t_varchar2                       default null,
    p_preserve_case                   in boolean                               default false,
    p_clear_disabled_constrainst_list in boolean                               default false,
    p_schema                          in varchar2                              default sys_context('USERENV', 'CURRENT_USER'),
    p_constraint_filter               in varchar2                              default null
);
--
--
--====================================================================================
-- disable_fk_constraints
--
-- Disables any enabled foreign key constraints on the tables passed in via p_tables.
-- The logged in user must have appropriate privileges on the tables defined by p_schema
-- and p_tables. 
--
-- If p_tables is null all enabled foreign key constraints on all tables
-- owned by p_schema (default CURRENT_USER) will be disabled.
--
-- The names of any disabled constraints will be stored in a private package variable 
-- for use by the procedure enable_disabled_constraints. If you need to access it, call 
-- the disabled_constraints function.Any disabling exception will be caught and store 
-- into theses private package variable : g_disable_exceptions and 
-- g_disable_exception_desc.
--
-- p_tables: List of tables whose enabled constraints will be disabled and the names 
--      will be stored in g_disabled_constraints. Null indicates all table of 
--      p_schema (default CURRENT_USER).
-- p_preserve_case: FALSE indicates all table names provided in p_tables will be 
--      changed to upper case. TRUE indicates to use the case of the table names provided
--      in p_tables.
-- p_clear_disabled_constrainst_list: TRUE clear the disabled_constrainst_list  
--                                    FALSE do nothing
-- p_schema: Specifies the schema that owns the constraints that will be disabled 
--      By default, the program will use CURRENT_USER.
-- p_constraint_filter: uses to filter the constraints based on their name.(Ex.'BUI%',
--      '%S_C0015709%'). The contraint name and the filter are case sensitive.
--      If null, no filter will be applied.
--
-- examples:
--  begin
--      insum$data_pkg_util.disable_fk_constraints(
--          p_tables => apex_t_varchar2('emp','dept', 'product', 'order','order_line')
--      );
--
--  begin
--      insum$data_pkg_util.disable_fk_constraints(
--          p_tables => apex_t_varchar2('emp','dept', 'product', 'order','order_line'),
--          p_preserve_case => false,
--          p_clear_disabled_constrainst_list => false,
--          p_schema => 'INTRACK',
--          p_constraint_filter ==> 'BUI%'
--      );
--  end;
--====================================================================================
procedure disable_fk_constraints(
    p_tables                          in apex_t_varchar2 default null,
    p_preserve_case                   in boolean         default false,
    p_clear_disabled_constrainst_list in boolean         default false,
    p_schema                          in varchar2        default sys_context('USERENV', 'CURRENT_USER'),
    p_constraint_filter               in varchar2 default null
);
--
--
--====================================================================================
-- disable_all_constraints
--
-- Disables any enabled constraints on the tables passed in via p_tables. Tables
-- must be owned by CURRENT_USER and the logged in user must have appropriate
-- privileges. If p_tables is null all enabled constraints on all tables owned by 
-- CURRENT_USER will be disabled.
--
-- The names of any disabled constraints will be stored in a private package variable 
-- for use by the procedure enable_disabled_constraints. If you need to access it, 
-- call the disabled_constraints function.Any disabling exception will be caught and 
-- store into theses private package variable : g_disable_exceptions and 
-- g_disable_exception_desc.
--
-- Note: This procedure does NOT cascade constraints. Hence, you may need to pass
--       the list of tables in p_tables in a particular order.
--
-- p_tables: List of tables whose enabled constraints will be disabled and the names 
--      will be stored in g_disabled_constraints. Null indicates all table of 
--      p_schema (default CURRENT_USER).
-- p_preserve_case: FALSE indicates all table names provided in p_tables will be 
--      changed to upper case. TRUE indicates to use the case of the table names provided
--      in p_tables.
-- p_clear_disabled_constrainst_list: TRUE clear the disabled_constrainst_list  
--                                    FALSE do nothing
-- p_schema: Specifies the schema that owns the constraints that will be disabled 
--      By default, the program will use CURRENT_USER.
-- p_constraint_filter: uses to filter the constraints based on their name.(Ex.'BUI%',
--      '%S_C0015709%'). The contraint name and the filter are case sensitive.
--      If null, no filter will be applied.
--
-- example:
--  begin
--      insum$data_pkg_util.disable_fk_constraints(
--          p_tables => apex_t_varchar2('emp','dept', 'product', 'order'),
--          p_preserve_case => false,
--          p_clear_disabled_constrainst_list => false,
--          p_schema => 'INTRACK',
--          p_constraint_filter ==> 'BUI%'
--      );
--  end;
--====================================================================================
procedure disable_all_constraints(
    p_tables                          in apex_t_varchar2 default null,
    p_preserve_case                   in boolean         default false,
    p_clear_disabled_constrainst_list in boolean         default false,
    p_schema                          in varchar2        default sys_context('USERENV', 'CURRENT_USER'),
    p_constraint_filter               in  varchar2       default null
);
--
--
--====================================================================================
-- disabled_constraints
--
-- Returns the disabled constraint list stored in the private package variable
-- g_disabled_constraints. 
--
-- example:
--  begin
--     l_res := insum$data_pkg_util.disabled_constraints;
--  end;
--====================================================================================
function disabled_constraints return apex_t_varchar2;
--
--
--====================================================================================
-- enable_disabled_constraints
--
-- Enables any disabled constraints stored in g_disabled_constraints. Any enabling 
-- exception will be caught and store into theses private package variable : 
-- g_enable_exceptions and g_enable_exception_desc.
--
-- example:
--  begin
--      insum$data_pkg_util.enable_disabled_constraints;
--  end;
--====================================================================================
--
procedure enable_disabled_constraints;
--
--
--====================================================================================
-- clear_disabled_constraint_list
--
-- Clear the constraints stored within g_disabled_constraints. This routine sets 
-- g_disabled_constraints to null.
--
-- example:
--  begin
--      insum$data_pkg_util.clear_disabled_constraint_list;
--  end;
--====================================================================================
procedure clear_disabled_constraint_list; 
--
--
--====================================================================================
-- disable_constraints_errors
--
-- Returns the disabled exception errors stored in the private package variable named 
-- g_disable_exceptions. This list of exceptions contains the name of the exceptions.
--
-- example:
--  begin
--     l_res := insum$data_pkg_util.disable_constraints_errors;
--  end;
--====================================================================================
function disable_constraints_errors return apex_t_varchar2;
--
--
--====================================================================================
-- enable_constaints_errors
--
-- Returns the enabled exception errors stored in the private package variable named 
-- g_enable_exceptions. This list of exceptions contains the name of the exceptions.
--
-- example:
--  begin
--     l_res := insum$data_pkg_util.enable_constraints_errors;
--  end;
--====================================================================================
function enable_constraints_errors return apex_t_varchar2;
--
--
--====================================================================================
-- increment_identity_columns
--
-- Increment the corresponding identity sequences to equal the maximum value currently 
-- in the column. This procedure operates on tables owned by the parsing schema.
-- 
-- p_tables: List of tables whose identity columns will be incremented. Null indicates 
--           all table of current_user. 
-- p_preserve_case: FALSE indicates all table names provided 
--                  in p_tables will be upper cased.TRUE indicates to use the case of the table names 
--                  provided in p_tables.
--
-- examples:
--  begin
--    -- increment all identity columns within the parsing schema
--    insum$data_pkg_util.increment_identity_columns;
--  end;
--
--  begin
--    insum$data_pkg_util.increment_identity_columns(
--          p_tables => apex_t_varchar2('emp','dept', 'product', 'order'),
--          p_preserve_case => false
--      );
--  end;
--====================================================================================
procedure increment_identity_columns (
    p_tables        in apex_t_varchar2 default null,
    p_preserve_case in boolean         default false
);

--
--    
--====================================================================================
-- increment_sequences
--
-- Increment the corresponding sequences to equal the maximum value currently in the 
-- column. This procedure operates on tables owned by the parsing schema.
-- 
-- *p_table_dot_columns: List of tables.column whose associated sequences will be 
--                       incremented. 
-- *p_sequences: list of associated sequences
-- p_preserve_case: FALSE indicates all table.columns names provided in 
--                 p_table_dot_columns will be upper cased.TRUE indicates to use the 
--                 case of the table.column names provided in p_table_dot_columns.
--
-- example:
--  begin
--      insum$data_pkg_util.increment_sequences(
--          p_table_dot_columns => apex_t_varchar2('emp.id','dept.id', 'product.id')
--          p_sequences => apex_t_varchar2('seq1','seq2','seq3','seq4','seq5')
--       );
--  end;
--====================================================================================
procedure increment_sequences (
    p_table_dot_columns          in  apex_t_varchar2,
    p_sequences                  in  apex_t_varchar2 ,
    p_preserve_case              in  boolean  default false
);
--
--
end INSUM$DATA_PKG_UTIL;
/