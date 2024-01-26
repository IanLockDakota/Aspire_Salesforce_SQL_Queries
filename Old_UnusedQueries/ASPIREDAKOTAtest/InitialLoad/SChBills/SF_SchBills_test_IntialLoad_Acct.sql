WITH SchBillsAspire AS (
    SELECT DISTINCT
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
        totals.TotalAmountDue AS TotalAmountDue__c,
        totals.TotalTaxAmountDue AS TotalTaxAmountDue__c,
        totals.TotalDue AS TotalDue__c,
        invoicecount.isInvoicedOccurrences AS isInvoicedOccurrences__C,
        totals.InvoicedTotalAmount AS InvoicedTotalAmount__c,
        invoicecount.unInvoicedOccurrences AS unInvoicedOccurrences__C,
        totals.UninvoicedTotalAmount AS UninvoicedTotalAmount__c,
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
        LEFT OUTER JOIN (
            SELECT 
                ContractOid,
                ScheduleDefinitionOid,
                MIN(startDate) AS startDate
            FROM PaymentStream
            WHERE isInvoiced = 1
            GROUP BY ContractOid,
                ScheduleDefinitionOid
        ) AS startD ON ps.ScheduleDefinitionOid = startD.ScheduleDefinitionOid
        LEFT OUTER JOIN (
            SELECT 
                ContractOid,
                ScheduleDefinitionOid,
                MAX(startDate) AS nextDate
            FROM PaymentStream
            WHERE isInvoiced = 0
            GROUP BY ContractOid,
                ScheduleDefinitionOid
        ) AS nextD ON ps.ScheduleDefinitionOid = nextD.ScheduleDefinitionOid
        LEFT OUTER JOIN (
            SELECT
                rb.ScheduleDefinitionOID, 
                SUM(CASE WHEN ps.isInvoiced = 1 THEN ps.Occurrences ELSE 0 END) AS isInvoicedOccurrences,
                SUM(CASE WHEN ps.isInvoiced = 0 THEN ps.Occurrences ELSE 0 END) AS unInvoicedOccurrences
            FROM RecurringBillable rb
            LEFT OUTER JOIN PaymentStream ps ON rb.ScheduleDefinitionOID = ps.ScheduleDefinitionOID
            GROUP BY rb.ScheduleDefinitionOID
        ) AS invoiceCount ON rb.ScheduleDefinitionOid = invoiceCount.ScheduleDefinitionOid
        LEFT OUTER JOIN (
            SELECT DISTINCT
                ps.ScheduleDefinitionOid, 
                MAX(psci.Amount) AS Amount, 
                MAX(psci.OnStreamTaxAmount) AS TaxAmount,
                MAX(psci.Amount) + MAX(psci.OnStreamTaxAmount) AS TotalAmount
            FROM PaymentStream ps
            LEFT OUTER JOIN PaymentStreamContractItem psci ON psci.paymentStreamOID = ps.PaymentStreamOid
            GROUP BY ps.ScheduleDefinitionOid
        ) AS amt ON rb.ScheduleDefinitionOID = amt.ScheduleDefinitionOid
        LEFT OUTER JOIN (
            SELECT
                ScheduleDefinitionOID,
                SUM(TotalAmountDue) AS TotalAmountDue,
                SUM(TotalTaxAmountDue) AS TotalTaxAmountDue,
                (SUM(TotalAmountDue) + SUM(TotalTaxAmountDue)) AS TotalDue,
                SUM(CASE WHEN isInvoiced = 1 THEN TotalAmountDue + TotalTaxAmountDue ELSE 0 END) AS InvoicedTotalAmount,
                SUM(CASE WHEN isInvoiced = 0 THEN TotalAmountDue + TotalTaxAmountDue ELSE 0 END) AS UninvoicedTotalAmount
            FROM (
                SELECT 
                    paymentStream.ScheduleDefinitionOid, 
                    paymentStream.PaymentStreamOid, 
                    paymentStream.Occurrences, 
                    paymentStream.isinvoiced, 
                    psci.amount,
                    psci.onStreamTaxAmount,
                    (SUM(paymentStream.Occurrences) * psci.amount) AS TotalAmountDue,
                    (SUM(paymentStream.Occurrences) * psci.onStreamTaxAmount) AS TotalTaxAmountDue
                FROM paymentStream
                LEFT OUTER JOIN PaymentStreamContractItem psci ON paymentStream.PaymentStreamOid = psci.PaymentStreamOid
                GROUP BY paymentStream.ScheduleDefinitionOid, 
                    paymentStream.PaymentStreamOid, 
                    paymentStream.Occurrences, 
                    paymentStream.isinvoiced, 
                    psci.amount,
                    psci.onStreamTaxAmount
            ) AS x
            GROUP BY ScheduleDefinitionOID
        ) AS totals ON rb.ScheduleDefinitionOID = totals.ScheduleDefinitionOid
    WHERE
        (C.IsBooked = 1) AND (C.CompanyOid = 1) AND (rb.contractOID IS NOT NULL)
),

SFAspireComparison AS (
    SELECT
        ID,
        Opportunity__c,
        contractOID__C, 
        RecurringBillableOid__c,
        Invoicedescription__c,
        Description__c, 
        ScheduleDefinitionOID__C, 
        IsFollowingRent__C, 
        IsCombinedWithRent__c, 
        IsProcessAsEFT__c, 
        IsBillAftertermination__c, 
        Frequency__c,
        TotalAmountDue__c,
        TotalTaxAmountDue__c,
        TotalDue__c,
        isInvoicedOccurrences__C,
        InvoicedTotalAmount__c,
        unInvoicedOccurrences__C,
        UninvoicedTotalAmount__c
    FROM [SALESFORCE3].[CDATA].[SALESFORCE].[Scheduled_Billables_ASPIRE__c]
),

OppIDTable AS (
	SELECT c.ContractOID, GV.ref_oid, GF.descr, ISNULL((GV.field_value), 'NULL') AS opportunityID
    FROM GenericField GF 
    LEFT OUTER JOIN cdataGenericValue GV ON GF.oid = GV.genf_oid 
    LEFT OUTER JOIN Contract c ON c.ContractOid = GV.ref_oid
    WHERE GF.oid = 23
    GROUP BY c.ContractOID, GV.ref_oid, GF.descr, GV.field_value
),

Subquery AS (
    SELECT
        C.contractOID AS contractOID__c,
		OppIDTable.Opportunity AS opportunity__c,
		SchBillsAspire.RecurringBillableOid__c,
		CASE
			WHEN SchBillAspire.IsFollowingRent__C  <> SFAspireComparison.IsFollowingRent__C 
			OR SchBillAspire.IsCombinedWithRent__c  <> SFAspireComparison.IsCombinedWithRent__c 
			OR SchBillAspire.IsProcessAsEFT__c  <> SFAspireComparison.IsProcessAsEFT__c 
			OR SchBillAspire.IsBillAftertermination__c  <> SFAspireComparison.IsBillAftertermination__c 
			OR SchBillAspire.TotalAmountDue__c <> SFAspireComparison.TotalAmountDue__c
			OR SchBillAspire.TotalTaxAmountDue__c <> SFAspireComparison.TotalTaxAmountDue__c
			OR SchBillAspire.TotalDue__c <> SFAspireComparison.TotalDue__c
			OR SchBillAspire.isInvoicedOccurrences__C <> SFAspireComparison.isInvoicedOccurrences__C
			OR SchBillAspire.InvoicedTotalAmount__c <> SFAspireComparison.InvoicedTotalAmount__c
			OR SchBillAspire.unInvoicedOccurrences__C <> SFAspireComparison.unInvoicedOccurrences__C
			OR SchBillAspire.UninvoicedTotalAmount__c <> SFAspireComparison.UninvoicedTotalAmount__c
			OR SchBillAspire.nextDate__c <> SFAspireComparison.nextDate__c
			OR SchBillAspire.NextPaymentAmount__c <> SFAspireComparison.NextPaymentAmount__c
			OR SchBillAspire.NextPaymentTaxAmount__c <> SFAspireComparison.NextPaymentTaxAmount__c
			OR SchBillAspire.NextPaymentTotalAmount__c <> SFAspireComparison.NextPaymentTotalAmount__c
			THEN 'Data Changed'
			ELSE 'No Change'
		END as ChangeStatus,
		SchBillsAspire.Invoicedescription__c,
		SchBillsAspire.Description__c,
		SchBillsAspire.ScheduleDefinitionOID__C,
		SchBillsAspire.IsFollowingRent__C, 
		SchBillsAspire.IsCombinedWithRent__c,
		SchBillsAspire.IsProcessAsEFT__c,
		SchBillsAspire.IsBillAftertermination__c,
		SchBillsAspire.Frequency__c,
		SchBillsAspire.TotalAmountDue__c,
		SchBillsAspire.TotalTaxAmountDue__c,
		SchBillsAspire.TotalDue__c,
		SchBillsAspire.isInvoicedOccurrences__C,
		SchBillsAspire.InvoicedTotalAmount__c,
		SchBillsAspire.unInvoicedOccurrences__C,
		SchBillsAspire.UninvoicedTotalAmount__c,
		SchBillsAspire.StartDate__c,
		SchBillsAspire.nextDate__c,
		SchBillsAspire.NextPaymentAmount__c,
		SchBillsAspire.NextPaymentTaxAmount__c,
		SchBillsAspire.NextPaymentTotalAmount__c
    FROM
        [ASPIRESQL].[AspireDakotaTest].[dbo].[Contract] C
		LEFT OUTER JOIN OppIDTable ON c.contractOID = OppIDTable.contractOID
		LEFT OUTER JOIN SchBillsAspire ON c.contractOID = SchBillsAspire.contractOID
		LEFT OUTER JOIN SFAspireComparison on c.contractOID = SFAspireComparison.contractOID
	WHERE
        (C.IsBooked = 1) AND (C.CompanyOid = 1)
	)

MERGE INTO Scheduled_Billables_ASPIRE__c_upsert AS Target USING (
    SELECT
		NULL AS ID,
		sbq.contractOID__C, 
		sbq.Opportunity__c,
		sbq.RecurringBillableOid__c,
		sbq.Invoicedescription__c,
		sbq.Description__c, 
		sbq.ScheduleDefinitionOID__C, 
		sbq.IsFollowingRent__C, 
		sbq.IsCombinedWithRent__c, 
		sbq.IsProcessAsEFT__c, 
		sbq.IsBillAftertermination__c, 
		sbq.Frequency__c,
		sbq.TotalAmountDue__c,
		sbq.TotalTaxAmountDue__c,
		sbq.TotalDue__c,
		sbq.isInvoicedOccurrences__C,
		sbq.InvoicedTotalAmount__c,
		sbq.unInvoicedOccurrences__C,
		sbq.UninvoicedTotalAmount__c,
		sbq.StartDate__c,
		sbq.nextDate__c,
		sbq.NextPaymentAmount__c,
		sbq.NextPaymentTaxAmount__c,
		sbq.NextPaymentTotalAmount__c
	FROM
		Subquery sbq
    ) AS Source ON Target.RecurringBillableOid__c = Source.RecurringBillableOid__c

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
        Target.TotalAmountDue = Source.TotalAmountDue__c,
        Target.TotalTaxAmountDue__c = Source.TotalTaxAmountDue__c,
        Target.TotalDue__c = Source.TotalDue__c,
        Target.isInvoicedOccurrences__C = Source.isInvoicedOccurrences__C,
        Target.InvoicedTotalAmount__c = Source.InvoicedTotalAmount__c,
        Target.unInvoicedOccurrences__C = Source.unInvoicedOccurrences__C,
        Target.UninvoicedTotalAmount__c = Source.UninvoicedTotalAmount__c,
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
        TotalAmountDue__c,
        TotalTaxAmountDue__c,
        TotalDue__c,
        isInvoicedOccurrences__C,
        InvoicedTotalAmount__c,
        unInvoicedOccurrences__C,
        UninvoicedTotalAmount__c,
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
        Source.TotalAmountDue__c,
        Source.TotalTaxAmountDue__c,
        Source.TotalDue__c,
        Source.isInvoicedOccurrences__C,
        Source.InvoicedTotalAmount__c,
        Source.unInvoicedOccurrences__C,
        Source.UninvoicedTotalAmount__c,
        Source.StartDate__c,
        Source.nextDate__c,
        Source.NextPaymentAmount__c,
        Source.NextPaymentTaxAmount__c,
        Source.NextPaymentTotalAmount__c
    );
