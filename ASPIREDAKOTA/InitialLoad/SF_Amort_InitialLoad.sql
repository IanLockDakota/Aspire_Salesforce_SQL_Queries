MERGE INTO Amort_ASPIRE__c_upsert AS Target
USING (SELECT
	null AS ID,
	amort.contractOID AS contractOID__c,
	amort.Date AS Date__c,
	pay.PayDate AS PayDate__c,
	amort.Source AS Source__c,
	amort.[Amount Financed] AS AmountFinanced__c,
	amort.Rate AS Rate__c,
	amort.Payment AS Payment__c,
	amort.Interest AS Interest__c,
	amort.Principal AS Principal__c,
	amort.Balance AS Balance__c,
	amort.ScheduleOid AS ScheduleOid__c,
	amort.lineitemoid AS LineItemOID__c,
	amort.LCDT AS LastChangeDateTime__c
FROM
	(SELECT 
		S.RefOid AS ContractOid,
		s.ScheduleOid,
		li.lineitemoid,
		CONVERT(DATE, LI.EventDate) AS Date, 
		LI.Note AS Source,
		CASE WHEN LI.IsLoan = 1 THEN LI.EventAmount ELSE '' END AS [Amount Financed],
		CASE WHEN LI.IsPayment = 1 THEN '' ELSE CAST(100 * LI.NewRate AS varchar(50)) END AS Rate,
		CASE WHEN LI.IsPayment = 1 THEN LI.EventAmount ELSE '0.00' END AS Payment,
		LI.InterestAccrued AS Interest, 
		LI.Principal, 
		LI.Balance,
		li.LastChangeDateTime AS LCDT
	FROM 
		Amortization.Schedule AS S
		INNER JOIN Amortization.LineItem AS LI ON S.ScheduleOid = LI.ScheduleOid
		LEFT OUTER JOIN Contract c ON s.RefOid = c.ContractOid
	WHERE 
		(S.RefType = 1)) AS amort
	LEFT OUTER JOIN
		(SELECT
			c.contractOID,
			I.InvoiceDetailOID,
			i.IsPaid,
			CAST(I.DueDate AS DATE) AS InvoiceDueDate,
			I.Description,
			I.InvoicePaymentMethod,
			I.OriginalDueAmount,
			I.CurrentDueAmount,
			p.appliedamount AS TotalAppliedAmount,
			CAST(p.paymentpostdate AS DATE) AS PayDate
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
					p.IsReturned = 0) as p ON i.InvoiceDetailOid = p.InvoiceDetailOid) AS pay ON amort.ContractOid = pay.ContractOid AND amort.Date = pay.InvoiceDueDate AND amort.Payment = pay.TotalAppliedAmount) AS Source
ON target.LineItemOID__c = source.LineItemOID__c

WHEN MATCHED THEN
    UPDATE SET
		Target.Date__c = Source.Date__c,
		Target.PayDate__c = Source.PayDate__c,
		Target.Source__c = Source.Source__c,
		Target.AmountFinanced__c = Source.AmountFinanced__c,
		Target.Rate__c = Source.Rate__c,
		Target.Payment__c = Source.Payment__c,
		Target.Interest__c = Source.Interest__c,
		Target.Principal__c = Source.Principal__c,
		Target.Balance__c = Source.Balance__c,
		Target.ScheduleOid__c = Source.ScheduleOid__c,
		Target.LastChangeDateTime__c = Source.LastChangeDateTime__c

WHEN NOT MATCHED THEN
    INSERT (
        ID,
		Date__c,
		PayDate__c,
		Source__c,
		AmountFinanced__c,
		Rate__c,
		Payment__c,
		Interest__c,
		Principal__c,
		Balance__c,
		ScheduleOid__c,
		LineItemOID__c,
		LastChangeDateTime__c

    ) VALUES (
        Source.ID,
		Source.Date__c,
		Source.PayDate__c,
		Source.Source__c,
		Source.AmountFinanced__c,
		Source.Rate__c,
		Source.Payment__c,
		Source.Interest__c,
		Source.Principal__c,
		Source.Balance__c,
		Source.ScheduleOid__c,
		Source.LineItemOID__c,
		Source.LastChangeDateTime__c
    );