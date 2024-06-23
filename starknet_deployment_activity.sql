WITH contract_deployments AS (
    SELECT
        DATE(block_timestamp) AS deployment_date,
        created_address AS contract_address
    FROM MCDW.transactions
    WHERE
        created_address IS NOT NULL
        AND block_timestamp >= DATE_SUB(CURRENT_DATE(), INTERVAL 1 YEAR)
),

weekly_contract_deployments AS (
    SELECT
        YEAR(deployment_date) AS deployment_year,
        WEEK(deployment_date) AS week_number,
        COUNT(DISTINCT contract_address) AS weekly_deployment_count
    FROM
        contract_deployments
    GROUP BY
        deployment_year, week_number
)

SELECT
    CONCAT(deployment_year, '-', LPAD(week_number, 2, '0')) AS week_range,
    weekly_deployment_count
FROM
    weekly_contract_deployments
ORDER BY
    deployment_year ASC, week_number ASC;
