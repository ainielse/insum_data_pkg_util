create or replace package body "INSUM$DATA_PKG_UTIL" as

    g_testing_state             boolean := false;

    -- Contains a list of constraint's names that have been disabled.
    g_disabled_constraints      apex_t_varchar2;

    -- Contains a list of constraint's names with errors
    g_disable_exceptions        apex_t_varchar2;
    g_disable_exception_desc    apex_t_varchar2;

    g_enable_exceptions         apex_t_varchar2;
    g_enable_exceptions_desc    apex_t_varchar2;
--
--
--==============================================================================
-- Public API, see specification
--==============================================================================
    procedure set_testing_on
    is
    begin
        g_testing_state := true;
    end set_testing_on;

--==============================================================================
-- Public API, see specification
--==============================================================================
    procedure set_testing_off
    is
    begin
        g_testing_state := false;
    end set_testing_off;

--==============================================================================
-- Public API, see specification
--==============================================================================
    procedure clear_disabled_constraint_list
        is
    begin
        g_disabled_constraints := null;
    exception
        when others
            then dbms_output.put_line('Error while clearing the disabled constraint list');

    end clear_disabled_constraint_list;
--
--
--==============================================================================
-- Public API, see specification
--==============================================================================
    procedure execute_disable (
        p_schema                in varchar2    default sys_context('USERENV','CURRENT_USER'),
        p_table                 in varchar2    default null,
        p_constraint_name       in varchar2    default null
    ) is
    begin

        if not g_testing_state then
            execute immediate 'alter table '
                || sys.dbms_assert.enquote_name(upper(p_schema)) || '.' || sys.dbms_assert.enquote_name(p_table)
                || ' disable constraint '
                || sys.dbms_assert.enquote_name(p_constraint_name) || ' ';
        else
            dbms_output.put_line('TESTING: disabling constraint ' || p_constraint_name || ' from ' || p_table);
        end if;

        apex_string.push(p_table => g_disabled_constraints, p_value => upper(p_schema) ||'.'|| p_constraint_name);

    exception
        when others then
            apex_string.push(p_table => g_disable_exceptions, p_value => p_constraint_name);
            apex_string.push(p_table => g_disable_exception_desc, p_value => p_constraint_name || ' : ' || SQLCODE);

    end execute_disable;
--
--
--==============================================================================
-- Public API, see specification
--==============================================================================
    procedure disable_constraints(
        p_constraint_type                 in user_constraints.constraint_name%type,
        p_tables                          in apex_t_varchar2                       default null,
        p_preserve_case                   in boolean                               default false,
        p_clear_disabled_constrainst_list in boolean                               default false,
        p_schema                          in varchar2                              default sys_context('USERENV', 'CURRENT_USER'),
        p_constraint_filter               in varchar2                              default null
    )
        is
        l_preserve_case number := case when p_preserve_case then 1 else 0 end;
        l_exception varchar2(4000);
    begin
        ---------------------------------------------------------------
        -- Disable all the constraints from the list of tables.
        -- Make sure the constraint name is enquote.
        ---------------------------------------------------------------
        if p_tables is null then
            for c in (
                select table_name
                from all_tables
                where owner = p_schema
                ) loop
                    for r in (
                        select constraint_name, table_name, constraint_type
                        from all_constraints
                        where owner = p_schema
                          and table_name = c.table_name
                          and constraint_type = p_constraint_type
                          and constraint_name like nvl(p_constraint_filter, constraint_name)
                          and status = 'enabled'
                        ) loop
                            execute_disable(
                                    p_schema            => p_schema,
                                    p_table             => r.table_name,
                                    p_constraint_name   => r.constraint_name
                                );
                        end loop;
                end loop;
        else
            for i in 1..p_tables.count loop
                    for r in (
                        select constraint_name, table_name, constraint_type
                        from all_constraints
                        where owner = p_schema
                          and table_name = decode(l_preserve_case, 1, p_tables(i), 0, upper(p_tables(i)))
                          and constraint_type = p_constraint_type
                          and constraint_name like nvl(p_constraint_filter, constraint_name)
                          and status = 'enabled'
                        ) loop
                            execute_disable(
                                    p_schema            => p_schema,
                                    p_table             => r.table_name,
                                    p_constraint_name   => r.constraint_name
                                );
                        end loop;
                end loop;
        end if;

        ---------------------------------------------------------------
        -- Check with multiple concurrent sessions
        ---------------------------------------------------------------
        if g_disable_exceptions is not null then

            select listagg(column_value, ', ') within group(order by column_value) as column_value
            into l_exception
            from table(g_disable_exceptions);

            raise_application_error(-20001, 'Unable to disable constraint : ' || l_exception);
        end if;

    end disable_constraints;
--
--
--==============================================================================
-- Public API, see specification
--==============================================================================
    procedure disable_fk_constraints (
        p_tables                            in  apex_t_varchar2    default null,
        p_preserve_case                     in  boolean            default false,
        p_clear_disabled_constrainst_list   in  boolean            default false,
        p_schema                            in  varchar2           default sys_context('USERENV','CURRENT_USER'),
        p_constraint_filter                 in  varchar2           default null
    )
        is
    begin
        disable_constraints(
                p_tables => p_tables,
                p_preserve_case => p_preserve_case,
                p_constraint_type => 'R',
                p_clear_disabled_constrainst_list => p_clear_disabled_constrainst_list,
                p_schema => p_schema,
                p_constraint_filter => p_constraint_filter
            );
    end disable_fk_constraints;
--
--
--==============================================================================
-- Public API, see specification
--==============================================================================
    procedure disable_all_constraints(
        p_tables                          in apex_t_varchar2     default null,
        p_preserve_case                   in boolean             default false,
        p_clear_disabled_constrainst_list in boolean             default false,
        p_schema                          in varchar2            default sys_context('USERENV','CURRENT_USER'),
        p_constraint_filter               in varchar2            default null
    )
        is
    begin
        disable_constraints(
                p_tables => p_tables,
                p_preserve_case => p_preserve_case,
                p_constraint_type => null,
                p_clear_disabled_constrainst_list => p_clear_disabled_constrainst_list,
                p_schema => p_schema,
                p_constraint_filter => null
            );
    end disable_all_constraints;
--
--
--==============================================================================
-- Public API, see specification
--==============================================================================
    function disabled_constraints return apex_t_varchar2
        is
    begin
        return g_disabled_constraints;
    end;
--
--
--==============================================================================
-- Public API, see specification
--==============================================================================
    procedure enable_disabled_constraints
        is

        l_table_name    user_constraints.table_name%type;
        l_exception     varchar2(4000);
        l_schema        varchar2(2000);
        l_constraint    varchar2(2000);

    begin
        for constr in (select column_value as constraint_name
                        from table(disabled_constraints()))
            loop
            ---------------------------------------------------------------
            -- Retrieves the table name associated with the constraint from
            -- user_constraints.
            ---------------------------------------------------------------
                begin
                    l_schema := apex_string.split(constr.constraint_name,'.')(1);
                    l_constraint := apex_string.split(constr.constraint_name,'.')(2);

                    select table_name
                    into l_table_name
                    from all_constraints
                    where owner = l_schema
                      and constraint_name = l_constraint;
                exception
                    when no_data_found
                        then dbms_output.put_line('No existing table associated with the constraint');
                end;
                ---------------------------------------------------------------
                -- Enable the constraint.
                ---------------------------------------------------------------
                begin
                    if not g_testing_state then
                        execute immediate 'alter table ' || l_table_name || ' enable constraint ' || sys.dbms_assert.enquote_name(constr.constraint_name);
                    else 
                        dbms_output.put_line('TESTING: Table : ' || l_table_name || ' -> constraint re-enabled : ' || constr.constraint_name);    
                    end if;
                    
                exception
                    when others then
                        apex_string.push(
                                p_table => g_enable_exceptions,
                                p_value => constr.constraint_name
                        );
                        apex_string.push(
                                p_table => g_enable_exceptions_desc,
                                p_value => constr.constraint_name || ' : ' || SQLCODE
                        );
                end;
                if g_enable_exceptions is not null then
                    select listagg(column_value, ', ') within group(order by column_value) as column_value
                    into l_exception
                    from table(g_enable_exceptions);
                    raise_application_error(-20001, 'Unable to enable constraint : ' || l_exception);
                end if;
            end loop;

    end enable_disabled_constraints;
--
--
--==============================================================================
-- Public API, see specification
--==============================================================================
    function disable_constraints_errors
        return apex_t_varchar2
        is
    begin
        return g_disable_exceptions;
    end disable_constraints_errors;
--
--
--==============================================================================
-- Public API, see specification
--==============================================================================
    function enable_constraints_errors return apex_t_varchar2
        is
    begin
        return g_enable_exceptions;
    end enable_constraints_errors;
--
--
--==============================================================================
-- Public API, see specification
--==============================================================================
    function get_column_max(p_table_name varchar2, p_column_name varchar2)
        return number is
        l_col_max number;
        l_table_count number;
        l_query_max varchar2(100);
    begin
        l_query_max := 'select max('|| p_table_name ||'.'|| p_column_name ||') from ' || p_table_name;
        execute immediate l_query_max into l_col_max;
        return l_col_max;
    end get_column_max;
--
--
--==============================================================================
-- Public API, see specification
--==============================================================================
    function get_sequence_value(p_value_type varchar2, p_seq_name varchar2)
        return number
        is
        l_seq_val number;
        l_query_max varchar2(100);
    begin
        begin
            ---------------------------------------------------------------
            -- Get the current sequence value or the next value depending
            -- on p_value_type.
            ---------------------------------------------------------------
            l_query_max := 'select ' || p_seq_name || case when p_value_type = 'current' then '.currval from dual' else '.nextval from dual' end;
            execute immediate l_query_max into l_seq_val;
        exception
            when others then
                if sqlcode = -8002 then
                    ---------------------------------------------------------------
                    -- You have to call .nextval at least once prior to calling .currval on a sequence
                    -- Call .nextval on the sequence.
                    -- Return 0 as the curr val.
                    ---------------------------------------------------------------
                    
                    l_query_max := 'select ' || p_seq_name || '.nextval FROM dual';
                    execute immediate l_query_max into l_seq_val;
                    return 0;
                else
                    raise;
                end if;
        end;
        return l_seq_val;
    end get_sequence_value;
--
--
--==============================================================================
-- Public API, see specification
--==============================================================================
    procedure increment_identity_columns (
        p_tables         in  apex_t_varchar2  default null,
        p_preserve_case  in  boolean          default false
    )
        is
        l_preserve_case     number := case when p_preserve_case then 1 else 0 end;
        l_seq_name          varchar(250);
        l_curr_max          number;
        l_curr_val          number;
        l_dummy             number;
    begin
        ---------------------------------------------------------------
        -- Retreives the identity sequence from user_tab_columns for all
        -- the tables contained in p_tables. data_default is the seq
        -- name.
        ---------------------------------------------------------------
        for constr in (
            select data_default, table_name, column_name
            from user_tab_columns atc
                     left join table(p_tables) pt
                               on decode(l_preserve_case, 1, atc.table_name, 0, upper(atc.table_name)) = pt.column_value
            where (p_tables is null or pt.column_value is not null)
              and identity_column = 'YES'
            ) loop
            ---------------------------------------------------------------
            -- Call .nextval on sequence not defined yet in the session.
            -- Return 0 as the curr val.
            ---------------------------------------------------------------
                l_curr_max := get_column_max(constr.table_name, constr.column_name);
                l_seq_name := substr(constr.data_default, 1, 32000);                                -- Convert datatype long -> varchar2
                l_seq_name := REGEXP_SUBSTR(l_seq_name, '"([^"]+)"\."([^"]+)"\.', 1, 1, NULL, 2);   -- Extract the seq name with the 2 "."
                loop
                    l_curr_val := get_sequence_value('current', l_seq_name);
                    l_dummy := get_sequence_value('next', l_seq_name);
                    exit when l_curr_val >= l_curr_max;
                end loop;
            end loop;
    end increment_identity_columns;
--
--
--==============================================================================
-- Public API, see specification
--==============================================================================
    procedure increment_sequences (
        p_table_dot_columns in apex_t_varchar2,
        p_sequences         in apex_t_varchar2 ,
        p_preserve_case     in boolean default false
    )
        is
        l_table     varchar2(1000);
        l_column    varchar2(1000);
        l_seq_name  varchar2(1000);
        l_curr_max  number;
        l_curr_val  number;
        l_dummy     number;
        l_maxes apex_t_number := apex_t_number();
    begin
        ---------------------------------------------------------------
        -- Keep the maximums in memory for each column.
        ---------------------------------------------------------------
        l_maxes.extend(p_table_dot_columns.count);

        ---------------------------------------------------------------
        -- For each <table_name>.<col_name> and sequence associated we
        -- increment the sequence value with the max of <col_name>.
        ---------------------------------------------------------------
        for i in 1..p_table_dot_columns.count loop
                l_table := regexp_substr(p_table_dot_columns(i), '^[^.]+');     -- Extract the table name (table_name.)
                l_column := regexp_substr(p_table_dot_columns(i), '[^.]+$');    -- Extract col name (.col)
                l_seq_name := sys.dbms_assert.enquote_name(p_sequences(i));
                l_curr_max := get_column_max(l_table, l_column);
                loop
                    l_curr_val := get_sequence_value('current', l_seq_name);
                    l_dummy := get_sequence_value('next', l_seq_name);
                    l_maxes(i) := l_curr_val;
                    ---------------------------------------------------------------
                    -- If the current is smaller than the max we continue.
                    ---------------------------------------------------------------
                    exit when l_curr_val >= l_curr_max;
                end loop;
            end loop;
    end increment_sequences;
--
--
end "INSUM$DATA_PKG_UTIL";
/