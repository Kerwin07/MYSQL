CREATE OR REPLACE VIEW clients_balance AS
SELECT 
	client_id,
    name,
    SUM(i.invoice_total - i.payment_total) AS clients_balance
    
FROM clients c
JOIN invoices i
	USING(client_id)
GROUP BY client_id