CREATE TABLE quarter_tbl(
    quarter_id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    quarter_item VARCHAR(2),
    PRIMARY KEY(quarter_id)
);

CREATE TABLE product_sales(
    product_id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    product_name VARCHAR(10),
    quarter_id INTEGER,
    year VARCHAR(5),
    sales INTEGER,
    CONSTRAINT fk_quarter
        FOREIGN KEY(quarter_id) 
            REFERENCES quarter_tbl(quarter_id)
);

INSERT INTO quarter_tbl(quarter_item) 
VALUES ('q1'), ('q2'), ('q3'), ('q4');

INSERT INTO product_sales(product_name, quarter_id, year, sales) VALUES
    ('ProductA', 1, 'y2017', 100),
    ('ProductA', 2, 'y2018', 150),
    ('ProductA', 2, 'y2018', 200),
    ('ProductA', 1, 'y2019', 300),
    ('ProductA', 2, 'y2020', 500),
    ('ProductA', 3, 'y2021', 450),
    ('ProductA', 1, 'y2022', 675),
    ('ProductB', 2, 'y2017', 0),
    ('ProductB', 1, 'y2018', 900),
    ('ProductB', 3, 'y2019', 1120),
    ('ProductB', 4, 'y2020', 750),
    ('ProductB', 3, 'y2021', 1500),
    ('ProductB', 2, 'y2022', 1980);

CREATE OR REPLACE FUNCTION get_dynamic_pivot_data(ref_cur refcursor, col_list text)
RETURNS refcursor AS $func$
DECLARE
    pivot_query text;
    year_query text;
    col_query text;
    var_col_list text;
    exec_query text;
    fix_col_tbl text;
BEGIN
    fix_col_tbl := 'tmp_fix_col_tbl';
    pivot_query := 
        'SELECT (ps.product_name || '', '' || q.quarter_item) as fix_col_list, ' 
            || 'ps.year, SUM(ps.sales) ' ||
        'FROM product_sales ps ' ||
        'INNER JOIN quarter_tbl q ' ||
        'ON ps.quarter_id = q.quarter_id ' ||
        'WHERE year in (' ||  col_list || ') ' || 
        'GROUP BY product_name, quarter_item, year ORDER BY 1,2,3 ';
    -- RAISE NOTICE 'pivot_query is : %', pivot_query;
 
    year_query := 'SELECT DISTINCT year FROM product_sales WHERE year in (' 
        ||  col_list || ') ' || 'ORDER BY 1 ';
    -- RAISE NOTICE 'year_query is: %', year_query;
 
    -- SELECT STRING_AGG (distinct year, ' int, ' ORDER BY year) || ' int' 
    -- FROM product_sales;
    col_query := 'SELECT STRING_AGG (distinct year, '' int, '' ORDER BY year) 
        || '' int'' FROM product_sales WHERE year in (' || col_list || ')';
    -- RAISE NOTICE 'col_query is: %', col_query;
 
    EXECUTE col_query into var_col_list;
    var_col_list := 'fix_col_list varchar, ' || var_col_list;
    -- RAISE NOTICE 'var_col_list is: %', var_col_list;

    exec_query := 'DROP TABLE IF EXISTS ' || fix_col_tbl;
    EXECUTE exec_query;

    exec_query := 'CREATE TEMP TABLE ' || fix_col_tbl 
                   || ' AS SELECT * FROM crosstab($$' 
                   || pivot_query || '$$, $$' || year_query 
                   || '$$) AS (' || var_col_list || ' )';
    -- RAISE NOTICE 'exec_query1 is %', exec_query;
    EXECUTE exec_query;

    col_query := 'SELECT STRING_AGG (distinct year, '', '' ORDER BY year) ' 
                    || 'FROM product_sales WHERE year IN (' || col_list || ')';
    EXECUTE col_query into col_list;
    -- RAISE NOTICE 'col_list is: %', col_list;

    exec_query := ' SELECT ' 
                   || 'SPLIT_PART(fix_col_list, '', '', 1) AS product_name, ' 
                   || 'SPLIT_PART(fix_col_list, '', '', 2) AS quarter_item, ' 
                   || col_list || ' FROM ' || fix_col_tbl || ' ORDER BY 1, 2'
                ;
    -- RAISE NOTICE 'exec_query2 is %', exec_query; 

    OPEN ref_cur FOR EXECUTE exec_query;
    RETURN ref_cur;
END;
$func$ LANGUAGE plpgsql;


