WITH stark_to_eth_price AS (
    SELECT
        'STARK/ETH' AS pair_name,
        block_date,
        parameters::amount1Out::$`low` / parameters::amount0In::$`low` AS price
    FROM mcdw.events
    WHERE
        chain_id = 5461067
        AND contract_address = '0x02ed66297d146ecd91595c3174da61c1397e8b7fcecf25d423b1ba6717b0ece9'
        AND event_name = 'Swap' 
        AND NOT reverted
        AND block_date = CURDATE()  -- Filter for today's date
        AND parameters::amount0In::$`low` > 0
        AND parameters::amount1Out::$`low` > 0
    GROUP BY
        block_date
),

stark_to_usdc_price AS (
    SELECT
        'STARK/USDC' AS pair_name,
        block_date,
        (parameters::amount1Out::$`low` / pow(10, 6)) / (parameters::amount0In::$`low` / pow(10, 18)) AS price
    FROM
        mcdw.events
    WHERE
        chain_id = 5461067
        AND contract_address = '0x05726725e9507c3586cc0516449e2c74d9b201ab2747752bb0251aaa263c9a26'
        AND event_name = 'Swap' 
        AND NOT reverted
        AND block_date = CURDATE()  -- Filter for today's date
        AND parameters::amount0In::$`low` > 0
        AND parameters::amount1Out::$`low` > 0
    GROUP BY
        block_date
),

eth_to_usdt_price AS (
    SELECT
        'ETH/USDT' AS pair_name,
        block_date,
        (parameters::amount1Out::$`low` / pow(10, 6)) / (parameters::amount0In::$`low` / pow(10, 18)) AS price
    FROM
        mcdw.events
    WHERE
        chain_id = 5461067
        AND contract_address = '0x045e7131d776dddc137e30bdd490b431c7144677e97bf9369f629ed8d3fb7dd6'
        AND event_name = 'Swap' 
        AND NOT reverted
        AND block_date = CURDATE()  -- Filter for today's date
        AND parameters::amount0In::$`low` > 0
        AND parameters::amount1Out::$`low` > 0
    GROUP BY
        block_date
),

dai_to_eth_price AS (
    SELECT
        'DAI/ETH' AS pair_name,
        block_date,
        (parameters::amount1Out::$`low` / pow(10, 18)) / (parameters::amount0In::$`low` / pow(10, 18)) AS price
    FROM
        mcdw.events
    WHERE
        chain_id = 5461067
        AND contract_address = '0x07e2a13b40fc1119ec55e0bcf9428eedaa581ab3c924561ad4e955f95da63138'
        AND event_name = 'Swap' 
        AND NOT reverted
        AND block_date = CURDATE()  -- Filter for today's date
        AND parameters::amount0In::$`low` > 0
        AND parameters::amount1Out::$`low` > 0
    GROUP BY
        block_date
)

SELECT
    pair_name,
    price
FROM
    (
        SELECT pair_name, block_date, price FROM stark_to_eth_price
        UNION ALL
        SELECT pair_name, block_date, price FROM stark_to_usdc_price
        UNION ALL
        SELECT pair_name, block_date, price FROM eth_to_usdt_price
        UNION ALL
        SELECT pair_name, block_date, price FROM dai_to_eth_price
    ) AS all_prices

