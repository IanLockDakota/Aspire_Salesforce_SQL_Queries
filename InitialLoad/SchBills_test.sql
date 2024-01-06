SELECT DISTINCT
	rb.contractOID, 
    rb.RecurringBillableOid,
	TC.Invoicedescription,
    rb.Description, 
    rb.ScheduleDefinitionOID, 
    rb.IsFollowingRent, 
    rb.IsCombinedWithRent, 
    rb.IsProcessAsEFT, 
    rb.IsBillAftertermination, 
    ps.Frequency,
	invoicecount.isInvoicedOccurrences,
	invoicecount.unInvoicedOccurrences,
	startD.startDate,
	nextD.nextDate,
	amt.Amount AS NextPaymentAmount,
	amt.OnStreamTaxAmount AS NextPaymentTaxAmount,
	amt.TotalAmount AS NextPaymentTotalAmount
FROM
	Contract c
	LEFT OUTER JOIN RecurringBillable rb ON c.contractOID = rb.ContractOid
    LEFT OUTER JOIN PaymentStream ps ON rb.ScheduleDefinitionOID = ps.ScheduleDefinitionOID
	LEFT OUTER JOIN TransactionCode TC ON rb.transactioncodeOID = tc.transactioncodeOID
	LEFT OUTER JOIN
		(SELECT 
			ContractOid,
			ScheduleDefinitionOid,
			MIN(startDate) AS startDate
		FROM
			PaymentStream
		WHERE
			isInvoiced = 1
		GROUP BY
			ContractOid,
			ScheduleDefinitionOid) AS startD on ps.ScheduleDefinitionOid = startD.ScheduleDefinitionOid
	LEFT OUTER JOIN
		(SELECT 
			ContractOid,
			ScheduleDefinitionOid,
			MAX(startDate) AS nextDate
		FROM
			PaymentStream
		WHERE
			isInvoiced = 0
		GROUP BY
			ContractOid,
			ScheduleDefinitionOid) AS nextD on ps.ScheduleDefinitionOid = nextD.ScheduleDefinitionOid
		LEFT OUTER JOIN 
		(SELECT
			rb.ScheduleDefinitionOID, 
			SUM(CASE WHEN ps.isInvoiced = 1 THEN ps.Occurrences ELSE 0 END) AS isInvoicedOccurrences,
			SUM(CASE WHEN ps.isInvoiced = 0 THEN ps.Occurrences ELSE 0 END) AS unInvoicedOccurrences
		FROM 
			RecurringBillable rb
			LEFT OUTER JOIN PaymentStream ps ON rb.ScheduleDefinitionOID = ps.ScheduleDefinitionOID
		GROUP BY
			rb.ScheduleDefinitionOID) as invoiceCount ON rb.ScheduleDefinitionOid = invoiceCount.ScheduleDefinitionOid
	LEFT OUTER JOIN
		(SELECT DISTINCT
			ps.ScheduleDefinitionOid, 
			MAX(psci.Amount), 
			MAX(psci.OnStreamTaxAmount),
			MAX(psci.Amount) + MAX(psci.OnStreamTaxAmount) AS TotalAmount
		FROM 
			PaymentStream ps
			LEFT OUTER JOIN PaymentStreamContractItem psci ON psci.paymentStreamOID = ps.PaymentStreamOid
		GROUP BY
			ps.ScheduleDefinitionOid) amt ON rb.RecurringBillableOid = amt.ScheduleDefinitionOid
WHERE
	(C.IsBooked = 1) AND (C.CompanyOid = 1) AND (rb.contractOID IS NOT NULL)
ORDER BY
	rb.contractOID