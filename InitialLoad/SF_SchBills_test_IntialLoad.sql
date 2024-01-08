
MERGE INTO ScheduledBillables_ASPIRE__c_upsert AS Target
USING (
	SELECT DISTINCT
	NULL AS ID,
	OppIDTable.Opportunity AS Opportunity__c,
	rb.contractOID AS contractOID__C, 
    rb.RecurringBillableOid AS RecurringBillableOid__c,
	TC.Invoicedescription AS Invoicedescription__c,
    rb.Description AS Description__c, 
    rb.ScheduleDefinitionOID AS ScheduleDefinitionOID__C, 
    rb.IsFollowingRent AS IsFollowingRent__C, 
    rb.IsCombinedWithRent AS IsCombinedWithRent__c, 
    rb.IsProcessAsEFT AS IsProcessAsEFT__c, 
    rb.IsBillAftertermination AS IsBillAftertermination__c, 
    ps.Frequency AS Frequency__c,
	invoicecount.isInvoicedOccurrences AS isInvoicedOccurrences__C,
	invoicecount.unInvoicedOccurrences AS unInvoicedOccurrences__C,
	CASE
		WHEN invoicecount.isInvoicedOccurrences = 0 THEN nextD.nextDate
		ELSE startD.startDate 
	END AS StartDate__c,
	CASE
		WHEN c.IsTerminated = 1 THEN NULL
		ELSE nextD.nextDate
	END AS nextDate__c,
	CASE
		WHEN c.IsTerminated = 1 THEN NULL
		WHEN invoicecount.unInvoicedOccurrences >= 1 THEN amt.Amount 
		ELSE NULL
	END AS NextPaymentAmount__c,
	CASE
		WHEN c.IsTerminated = 1 THEN NULL
		WHEN invoicecount.unInvoicedOccurrences >= 1 THEN amt.TaxAmount 
		ELSE NULL
	END AS NextPaymentTaxAmount__c,
	CASE
		WHEN c.IsTerminated = 1 THEN NULL
		WHEN invoicecount.unInvoicedOccurrences >= 1 THEN amt.TotalAmount 
		ELSE NULL
	END AS NextPaymentTotalAmount__c
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
			MAX(psci.Amount) as Amount, 
			MAX(psci.OnStreamTaxAmount) as TaxAmount,
			MAX(psci.Amount) + MAX(psci.OnStreamTaxAmount) AS TotalAmount
		FROM 
			PaymentStream ps
			LEFT OUTER JOIN PaymentStreamContractItem psci ON psci.paymentStreamOID = ps.PaymentStreamOid
		GROUP BY
			ps.ScheduleDefinitionOid) amt ON rb.ScheduleDefinitionOID = amt.ScheduleDefinitionOid
	LEFT OUTER JOIN
		
WHERE
	(C.IsBooked = 1) AND (C.CompanyOid = 1) AND (rb.contractOID IS NOT NULL)) AS Source
ON Target.RecurringBillableOid__c = Source.RecurringBillableOid__c

WHEN MATCHED THEN
    UPDATE SET
        Target.Opportunity__c = Source.Opportunity__c,
        Target.Invoicedescription__c = Source.Invoicedescription__c,
        Target.Description__c = Source.Description__c,
        Target.ScheduleDefinitionOID__C = Source.ScheduleDefinitionOID__C,
        Target.IsFollowingRent__C = Source.IsFollowingRent__C,
        Target.IsCombinedWithRent__c = Source.IsCombinedWithRent__c,
        Target.IsProcessAsEFT__c = Source.IsProcessAsEFT__c,
		Target.IsBillAftertermination__c = Source.IsBillAftertermination__c,
        Target.Frequency__c = Source.Frequency__c,
        Target.isInvoicedOccurrences__C = Source.isInvoicedOccurrences__C,
        Target.unInvoicedOccurrences__C = Source.unInvoicedOccurrences__C,
        Target.StartDate__c = Source.StartDate__c,
        Target.nextDate__c = Source.nextDate__c,
        Target.NextPaymentAmount__c = Source.NextPaymentAmount__c,
        Target.NextPaymentTaxAmount__c = Source.NextPaymentTaxAmount__c,
        Target.NextPaymentTotalAmount__c = Source.NextPaymentTotalAmount__c

WHEN NOT MATCHED THEN
    INSERT (
        ID,
        Opportunity__c,
        RecurringBillableOid__c,
        Invoicedescription__c,
        Description__c,
        ScheduleDefinitionOID__C,
        IsFollowingRent__C,
        IsCombinedWithRent__c,
        IsProcessAsEFT__c,
        IsBillAftertermination__c,
        Frequency__c,
        isInvoicedOccurrences__C,
        unInvoicedOccurrences__C,
        StartDate__c,
        nextDate__c,
        NextPaymentAmount__c,
        NextPaymentTaxAmount__c,
        NextPaymentTotalAmount__c

    ) VALUES (
        Source.ID,
        Source.Opportunity__c,
        Source.RecurringBillableOid__c,
        Source.Invoicedescription__c,
        Source.Description__c,
        Source.ScheduleDefinitionOID__C,
        Source.IsFollowingRent__C,
        Source.IsCombinedWithRent__c,
        Source.IsProcessAsEFT__c,
        Source.IsBillAftertermination__c,
        Source.Frequency__c,
        Source.isInvoicedOccurrences__C,
        Source.unInvoicedOccurrences__C,
        Source.StartDate__c,
        Source.nextDate__c,
        Source.NextPaymentAmount__c,
        Source.NextPaymentTaxAmount__c,
        Source.NextPaymentTotalAmount__c
    
    );