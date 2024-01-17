SELECT 
		S.RefOid AS ContractOid,
		s.ScheduleOid,
		li.lineitemoid,
		CONVERT(DATE, LI.EventDate) AS Date, 
		LI.Note AS Source,
		CASE WHEN LI.IsLoan = 1 THEN LI.EventAmount ELSE '' END AS [Amount Financed],
		CASE WHEN LI.IsPayment = 1 THEN '' ELSE CAST(100 * LI.NewRate AS varchar(50)) + '%' END AS Rate,
		CASE WHEN LI.IsPayment = 1 THEN LI.EventAmount ELSE '0.00' END AS Payment,
		LI.InterestAccrued AS Interest, 
		LI.Principal, 
		LI.Balance,
		S.LastChangeDateTime AS LCDT
	FROM 
		Amortization.Schedule AS S
		INNER JOIN Amortization.LineItem AS LI ON S.ScheduleOid = LI.ScheduleOid
		LEFT OUTER JOIN Contract c ON s.RefOid = c.ContractOid
	WHERE 
		(S.RefType = 1)
ORDER BY 
	ContractOid, Date
-------------------------------------------------------------
SELECT
	c.contractOID,
	I.InvoiceDetailOID,
	i.IsPaid,
	CAST(I.DueDate AS DATE) AS InvoiceDueDate,
	CAST(p.paymentpostdate AS DATE) AS PayInFullDate,
	I.Description,
	I.InvoicePaymentMethod,
	I.OriginalDueAmount,
	I.CurrentDueAmount,
	p.appliedamount AS TotalAppliedAmount
FROM
	contract c
	LEFT OUTER JOIN
		(SELECT
			ID.ContractOID,
			ID.InvoiceDetailOID,
			ID.DueDate,
			ID.OriginalDueAmount,
			ID.CurrentDueAmount,
			TC.Description,
			LTVI.data_value AS InvoicePaymentMethod,
			ID.isPaid
		FROM 
			InvoiceDetail ID
			LEFT OUTER JOIN TransactionCode TC ON ID.TransactionCodeOid = TC.TransactionCodeOid
			LEFT OUTER JOIN LTIValues LTVI ON LTVI.OID = ID.OpenClosedOid
		WHERE
			ID.ContractOID IS NOT NULL
			AND TC.Description IN ('Lease Payment', 'EFA Payment')) AS I on c.contractOID = i.ContractOid
	LEFT OUTER JOIN
		(SELECT
			p.ContractOID,
			P.PaymentOid,
			ID.InvoiceDetailOid,
			LTIV.descr,
			CRD.AppliedAmount,
			p.IsReturned,
			P.PostDate AS PaymentPostDate,
			P.EffectiveDate AS PaymentEffectiveDate
		FROM 
			Payment P
			LEFT OUTER JOIN LTIValues LTIV ON LTIV.OID = P.PaymentMethodOid
			LEFT OUTER JOIN CashReceiptHeader CRH ON CRH.PaymentOID = P.PaymentOID
			LEFT OUTER JOIN CashReceiptBillable CRB ON CRB.CashReceiptHeaderOID = CRH.CashReceiptHeaderOID
			LEFT OUTER JOIN CashReceiptDetail CRD ON CRD.CashReceiptBillableOid = CRB.CashReceiptBillableOid
			LEFT OUTER JOIN InvoiceDetail ID ON ID.InvoiceDetailOid = CRD.InvoiceDetailOid
		WHERE
			p.IsReturned = 0) as p ON i.InvoiceDetailOid = p.InvoiceDetailOid
ORDER BY
	c.ContractOid, i.InvoiceDetailOid
-------------------------------------------------------------
SELECT
	c.contractOID,
	I.InvoiceDetailOID,
	i.IsPaid,
	CAST(I.DueDate AS DATE) AS InvoiceDueDate,
	I.Description,
	I.InvoicePaymentMethod,
	I.OriginalDueAmount,
	I.CurrentDueAmount,
	SUM(p.appliedamount) AS TotalAppliedAmount,
	CAST(MAX(p.paymentpostdate) AS DATE) AS PayInFullDate
FROM
	contract c
	LEFT OUTER JOIN
		(SELECT
			ID.ContractOID,
			ID.InvoiceDetailOID,
			ID.DueDate,
			ID.OriginalDueAmount,
			ID.CurrentDueAmount,
			TC.Description,
			LTVI.data_value AS InvoicePaymentMethod,
			ID.isPaid
		FROM 
			InvoiceDetail ID
			LEFT OUTER JOIN TransactionCode TC ON ID.TransactionCodeOid = TC.TransactionCodeOid
			LEFT OUTER JOIN LTIValues LTVI ON LTVI.OID = ID.OpenClosedOid
		WHERE
			ID.ContractOID IS NOT NULL
			AND TC.Description IN ('Lease Payment', 'EFA Payment')) AS I on c.contractOID = i.ContractOid
	LEFT OUTER JOIN
		(SELECT
			p.ContractOID,
			P.PaymentOid,
			ID.InvoiceDetailOid,
			LTIV.descr,
			CRD.AppliedAmount,
			p.IsReturned,
			P.PostDate AS PaymentPostDate,
			P.EffectiveDate AS PaymentEffectiveDate
		FROM 
			Payment P
			LEFT OUTER JOIN LTIValues LTIV ON LTIV.OID = P.PaymentMethodOid
			LEFT OUTER JOIN CashReceiptHeader CRH ON CRH.PaymentOID = P.PaymentOID
			LEFT OUTER JOIN CashReceiptBillable CRB ON CRB.CashReceiptHeaderOID = CRH.CashReceiptHeaderOID
			LEFT OUTER JOIN CashReceiptDetail CRD ON CRD.CashReceiptBillableOid = CRB.CashReceiptBillableOid
			LEFT OUTER JOIN InvoiceDetail ID ON ID.InvoiceDetailOid = CRD.InvoiceDetailOid
		WHERE
			p.IsReturned = 0) as p ON i.InvoiceDetailOid = p.InvoiceDetailOid
GROUP BY
	c.contractOID,
	I.InvoiceDetailOID,
	i.IsPaid,
	I.DueDate,
	I.Description,
	I.InvoicePaymentMethod,
	I.OriginalDueAmount,
	I.CurrentDueAmount
ORDER BY
	c.ContractOid, i.InvoiceDetailOid