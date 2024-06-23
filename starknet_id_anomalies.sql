with transfer_pairs as (
    select parameters::$`from` as from_address,
        parameters::$`to` as to_address,
        parameters::$`token_id` as token_id,
        count(*) as forward_count
    from MCDW.events
    where 
        contract_address = "0x05dbdedc203e92749e2e746e2d40a768d966bd243df04a6b712e222bc040a9af"
        and event_name = "Transfer"
        and from_address !="0x0000000000000000000000000000000000000000"
        and to_address != "0x0000000000000000000000000000000000000000"
    group by 
        from_address, 
        to_address, 
        token_id
)


select tp1.from_address,
    tp1.to_address,
    (SUBSTRING(tp1.token_id, 50)) as token_id,
    (tp1.forward_count + COALESCE(tp2.forward_count, 0)) AS transfer_count
from 
    transfer_pairs tp1
left join 
    transfer_pairs tp2
on 
    tp1.from_address = tp2.to_address
    AND tp1.to_address = tp2.from_address
    AND tp1.token_id = tp2.token_id
having 
    (tp1.forward_count + COALESCE(tp2.forward_count, 0)) > 5
limit 30;