with daily_ekubo_eth_price as (
    select
    median(
        (parameters::delta::amount1::mag :> DECIMAL(65,0) / pow(10,6)) /
        (parameters::delta::amount0::mag :> DECIMAL(65,0) / pow(10,18))
    ) as median_eth_price
    from mcdw.events
    where chain_id=5461067
    and contract_address = '0x00000005dd3d2f4429af886cd1a3b08289dbcea99a294197e9eb43b0e0325b4b' -- Ekubo Core
    and parameters::pool_key::$token0 = '0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7' -- ETH Token
    and parameters::pool_key::$token1 = '0x053c91253bc9682c04929ca02ed00b3e423f6710d2ee7e0d5ebb06f3ecf368a8' -- USDC Token address
    and event_name = 'Swapped' -- Listen to swap event
    and not reverted
    and block_timestamp >= date_sub(now(), interval 24 hour)
),

blob_transactions AS (
    SELECT 
        DATE(block_timestamp) AS day,
        AVG(gas_price) AS avg_gas_price
    FROM MCDW.blocks
    WHERE 
        l1_da_mode = 'blob'
        AND block_timestamp >= DATE_SUB(CURRENT_DATE(), INTERVAL 1 MONTH)
    GROUP BY 
        DATE(block_timestamp)
),

calldata_transactions AS (
    SELECT 
        DATE(block_timestamp) AS day,
        AVG(gas_price) AS avg_gas_price
    FROM MCDW.blocks
    WHERE 
        l1_da_mode = 'calldata'
        AND block_timestamp >= DATE_SUB(DATE_SUB(CURRENT_DATE(), INTERVAL 1 YEAR), INTERVAL 1 MONTH)
        AND block_timestamp < DATE_SUB(CURRENT_DATE(), INTERVAL 1 YEAR)
    GROUP BY 
        DATE(block_timestamp)
)

SELECT 
    b.day AS blob_day,
    c.day AS calldata_day,
    ROUND(((b.avg_gas_price/1e18) * dep.median_eth_price), 7) AS blob_avg_gas_price_in_usd,
    ROUND(((c.avg_gas_price/1e18) * dep.median_eth_price), 7) AS calldata_avg_gas_price_last_year_in_usd
FROM 
    blob_transactions b
LEFT JOIN 
    calldata_transactions c
ON 
    DATE_ADD(b.day, INTERVAL -1 YEAR) = c.day
CROSS JOIN 
    daily_ekubo_eth_price dep
ORDER BY 
    blob_day;
