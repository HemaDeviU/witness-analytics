with daily_ekubo_stark_price as (
    select
    median(
        (parameters::delta::amount1::mag :> DECIMAL(65,0) / pow(10,6)) /
        (parameters::delta::amount0::mag :> DECIMAL(65,0) / pow(10,18))
    ) as median_stark_price
    from mcdw.events
    where chain_id=5461067
    and contract_address = '0x00000005dd3d2f4429af886cd1a3b08289dbcea99a294197e9eb43b0e0325b4b' -- Ekubo Core
    and parameters::pool_key::$token0 = '0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d' -- STRK Token address
    and parameters::pool_key::$token1 = '0x053c91253bc9682c04929ca02ed00b3e423f6710d2ee7e0d5ebb06f3ecf368a8' -- USDC Token address
    and event_name = 'Swapped' -- Listen to swap event
    and not reverted
    and block_timestamp >= date_sub(now(), interval 24 hour)
),

starknet_contracts AS (
    SELECT DISTINCT contract_address as contract
    FROM MCDW.events
),


strk_transfers AS (
    SELECT
        parameters::$`from` AS from_address,
        parameters::$`to` AS to_address,
        CAST(parameters::`value`::$`low` AS DECIMAL(65, 0)) / POW(10, 18) AS strk_amount,
        block_timestamp
    FROM MCDW.events
    WHERE
        contract_address = '0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d'
        AND event_name = 'Transfer'
),

address_balances AS (
    SELECT
        from_address AS address,
        -SUM(strk_amount) AS strk_balance
    FROM
        strk_transfers
    WHERE
        from_address != '0x0000000000000000000000000000000000000000'
    GROUP BY
        from_address

    UNION ALL

    SELECT
        to_address AS address,
        SUM(strk_amount) AS strk_balance
    FROM
        strk_transfers
    WHERE
        to_address != '0x0000000000000000000000000000000000000000'
    GROUP BY
        to_address
),

aggregated_balances AS (
    SELECT
        address,
        SUM(strk_balance) AS total_strk_balance
    FROM
        address_balances
    GROUP BY
        address
),

whales AS (
    SELECT
        address,
        total_strk_balance
    FROM
        aggregated_balances
    WHERE
        total_strk_balance > 10000
),

recent_transfers AS (
    SELECT
        t.from_address,
        t.to_address,
        t.strk_amount,
        t.block_timestamp,
        ROW_NUMBER() OVER (PARTITION BY t.from_address ORDER BY t.block_timestamp DESC) AS rn_from,
        ROW_NUMBER() OVER (PARTITION BY t.to_address ORDER BY t.block_timestamp DESC) AS rn_to
    FROM
        strk_transfers t
    JOIN
        whales w
    ON
        t.from_address = w.address OR t.to_address = w.address
)

SELECT
    w.address AS whale_address,
    w.total_strk_balance * dep.median_stark_price AS whale_strk_balance_in_usd,
    COALESCE(rt_from.strk_amount, rt_to.strk_amount) * dep.median_stark_price AS last_transfer_amount_in_usd,
    COALESCE(rt_from.block_timestamp, rt_to.block_timestamp) AS last_transfer_timestamp
FROM
    whales w
LEFT JOIN
    recent_transfers rt_from
ON
    w.address = rt_from.from_address AND rt_from.rn_from = 1
LEFT JOIN
    recent_transfers rt_to
ON
    w.address = rt_to.to_address AND rt_to.rn_to = 1
CROSS JOIN 
    daily_ekubo_stark_price dep
WHERE
    w.address NOT IN (SELECT contract FROM starknet_contracts)
ORDER BY
    w.total_strk_balance DESC
LIMIT 100;