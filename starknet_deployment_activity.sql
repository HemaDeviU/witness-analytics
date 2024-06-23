WITH contract_deployments AS (
    SELECT
        DATE(block_timestamp) AS deployment_date,
        created_address AS contract_address
    FROM MCDW.transactions
    WHERE
        created_address IS NOT NULL
        AND block_timestamp >= DATE_SUB(CURRENT_DATE(), INTERVAL 1 YEAR)
),

daily_contract_deployments AS (
    SELECT
        deployment_date,
        COUNT(DISTINCT contract_address) AS daily_deployment_count
    FROM
        contract_deployments
    GROUP BY
        deployment_date
)

SELECT
    dcd.deployment_date,
    dcd.daily_deployment_count
FROM
    daily_contract_deployments dcd
ORDER BY
    dcd.deployment_date DESC;
