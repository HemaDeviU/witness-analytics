WITH contract_transactions AS (
    SELECT 
        to_address as contract_address, 
        COUNT(*) as transaction_count
    FROM MCDW.transactions
    WHERE to_address IS NOT NULL
    GROUP BY to_address
),

contract_events AS (
    SELECT 
        contract_address, 
        COUNT(*) as event_count
    FROM MCDW.events
    GROUP BY contract_address
)

SELECT 
    ct.contract_address,
    ct.transaction_count,
    COALESCE(ce.event_count, 0) as event_count
FROM contract_transactions ct
LEFT JOIN contract_events ce ON ct.contract_address = ce.contract_address
ORDER BY ct.transaction_count DESC
LIMIT 10;
