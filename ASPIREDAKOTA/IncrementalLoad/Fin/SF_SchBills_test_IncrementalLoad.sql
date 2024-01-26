-- DATETIME VARIABLES
DECLARE @start DATETIME = DATEADD(HOUR, -1, GETDATE())
DECLARE @end DATETIME = GETDATE()

MERGE INTO Scheduled_Billables_ASPIRE__c_upsert AS Target USING (
                SELECT DISTINCT
        NULL AS ID,
        OppIDTable.OpportunityID AS Opportunity__c,
        rb.contractOID AS contractOID__C, 
        rb.RecurringBillableOid AS RecurringBillableOid__c,
        TC.Invoicedescription AS Invoicedescription__c,
        rb.Description AS Description__c, 
        rb.ScheduleDefinitionOID AS ScheduleDefinitionOID__C, 
        rb.IsFollowingRent AS IsFollowingRent__C, 
        rb.IsCombinedWithRent AS IsCombinedWithRent__c, 
        rb.IsProcessAsEFT AS IsProcessAsEFT__c, 
        rb.IsBillAftertermination AS IsBillAftertermination__c, 
        freq.descr AS Frequency__c,
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
        END AS NextPaymentTotalAmount__c,
        rb.LastChangeOperator AS LastChangeOperator__c,
		lcdt.GreatestLastchangeDateTime AS LastChangeDateTime__c
    FROM
       [ASPIRESQL].[AspireDakota].[dbo].[Contract] c
        LEFT OUTER JOIN [ASPIRESQL].[AspireDakota].[dbo].[RecurringBillable] rb ON c.contractOID = rb.ContractOid
        LEFT OUTER JOIN [ASPIRESQL].[AspireDakota].[dbo].[PaymentStream] ps ON rb.ScheduleDefinitionOID = ps.ScheduleDefinitionOID
        LEFT OUTER JOIN [ASPIRESQL].[AspireDakota].[dbo].[TransactionCode] TC ON rb.transactioncodeOID = tc.transactioncodeOID
        LEFT OUTER JOIN (
            SELECT 
                ContractOid,
                ScheduleDefinitionOid,
                MIN(startDate) AS startDate
            FROM [ASPIRESQL].[AspireDakota].[dbo].[PaymentStream]
            WHERE isInvoiced = 1
            GROUP BY ContractOid,
                ScheduleDefinitionOid
        ) AS startD ON ps.ScheduleDefinitionOid = startD.ScheduleDefinitionOid
        LEFT OUTER JOIN (
            SELECT 
                ContractOid,
                ScheduleDefinitionOid,
                MAX(startDate) AS nextDate
            FROM [ASPIRESQL].[AspireDakota].[dbo].[PaymentStream]
            WHERE isInvoiced = 0
            GROUP BY ContractOid,
                ScheduleDefinitionOid
        ) AS nextD ON ps.ScheduleDefinitionOid = nextD.ScheduleDefinitionOid
        LEFT OUTER JOIN (
            SELECT
                rb.ScheduleDefinitionOID, 
                SUM(CASE WHEN ps.isInvoiced = 1 THEN ps.Occurrences ELSE 0 END) AS isInvoicedOccurrences,
                SUM(CASE WHEN ps.isInvoiced = 0 THEN ps.Occurrences ELSE 0 END) AS unInvoicedOccurrences
            FROM [ASPIRESQL].[AspireDakota].[dbo].[RecurringBillable] rb
            LEFT OUTER JOIN [ASPIRESQL].[AspireDakota].[dbo].[PaymentStream] ps ON rb.ScheduleDefinitionOID = ps.ScheduleDefinitionOID
            GROUP BY rb.ScheduleDefinitionOID
        ) AS invoiceCount ON rb.ScheduleDefinitionOid = invoiceCount.ScheduleDefinitionOid
        LEFT OUTER JOIN (
            SELECT DISTINCT
                ps.ScheduleDefinitionOid, 
                MAX(psci.Amount) AS Amount, 
                MAX(psci.OnStreamTaxAmount) AS TaxAmount,
                MAX(psci.Amount) + MAX(psci.OnStreamTaxAmount) AS TotalAmount
            FROM [ASPIRESQL].[AspireDakota].[dbo].[PaymentStream] ps
            LEFT OUTER JOIN [ASPIRESQL].[AspireDakota].[dbo].[PaymentStreamContractItem] psci ON psci.paymentStreamOID = ps.PaymentStreamOid
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
                FROM [ASPIRESQL].[AspireDakota].[dbo].[paymentStream]
                LEFT OUTER JOIN [ASPIRESQL].[AspireDakota].[dbo].[PaymentStreamContractItem] psci ON paymentStream.PaymentStreamOid = psci.PaymentStreamOid
                GROUP BY paymentStream.ScheduleDefinitionOid, 
                    paymentStream.PaymentStreamOid, 
                    paymentStream.Occurrences, 
                    paymentStream.isinvoiced, 
                    psci.amount,
                    psci.onStreamTaxAmount
            ) AS x
            GROUP BY ScheduleDefinitionOID
        ) AS totals ON rb.ScheduleDefinitionOID = totals.ScheduleDefinitionOid
        LEFT OUTER JOIN
           (SELECT c.ContractOID, GV.ref_oid, GF.descr, ISNULL((GV.field_value), 'NULL') AS opportunityID
            FROM [ASPIRESQL].[AspireDakota].[dbo].[GenericField] GF 
            LEFT OUTER JOIN [ASPIRESQL].[AspireDakota].[dbo].[cdataGenericValue] GV ON GF.oid = GV.genf_oid 
            LEFT OUTER JOIN [ASPIRESQL].[AspireDakota].[dbo].[Contract] c ON c.ContractOid = GV.ref_oid
            WHERE GF.oid = 23
            GROUP BY c.ContractOID, GV.ref_oid, GF.descr, GV.field_value) AS OppIdTable ON rb.contractOID = OppIDTable.contractOID
		LEFT OUTER JOIN
			(SELECT
				rb.RecurringBillableOid,
				CASE 
					WHEN rb.LastChangeDateTime >= ps.LastChangeDateTime AND rb.LastChangeDateTime >= psci.LastChangeDateTime THEN rb.LastChangeDateTime
					WHEN ps.LastChangeDateTime >= rb.LastChangeDateTime AND ps.LastChangeDateTime >= psci.LastChangeDateTime THEN ps.LastChangeDateTime
					ELSE psci.LastChangeDateTime
				END AS GreatestLastchangeDateTime,
				rb.LastChangeDateTime AS rblcdt,
				ps.LastChangeDateTime AS pslcdt,
				psci.LastChangeDateTime AS pscilcdt
			FROM 
				[ASPIRESQL].[AspireDakota].[dbo].[RecurringBillable] rb
				LEFT OUTER JOIN [ASPIRESQL].[AspireDakota].[dbo].[paymentStream] ps ON rb.ScheduleDefinitionOid = ps.ScheduleDefinitionOid
                LEFT OUTER JOIN [ASPIRESQL].[AspireDakota].[dbo].[PaymentStreamContractItem] psci ON ps.PaymentStreamOid = psci.PaymentStreamOid) AS lcdt ON rb.RecurringBillableOid = lcdt.RecurringBillableOid
                LEFT OUTER JOIN (SELECT DISTINCT
                                    ps.ScheduleDefinitionOid,
                                    ps.Frequency,
                                    lti.descr
                                FROM
                                    [ASPIRESQL].[AspireDakota].[dbo].[PaymentStream] ps
                                    LEFT OUTER JOIN [ASPIRESQL].[AspireDakota].[dbo].[LTIValues] lti ON ps.Frequency = lti.data_value
                                WHERE 
                                    lti.table_key = 'PYMT_FREQUENCY') as freq ON rb.ScheduleDefinitionOid = freq.ScheduleDefinitionOid
    WHERE
        (C.IsBooked = 1) AND (C.CompanyOid = 1) AND (rb.contractOID IS NOT NULL) AND (lcdt.GreatestLastchangeDateTime BETWEEN @start AND @end) AND (OppIDTable.opportunityID IS NOT NULL)
    ) AS Source ON Target.ScheduleDefinitionOID__C = Source.ScheduleDefinitionOID__C

WHEN MATCHED THEN
    UPDATE SET
        Target.Opportunity__c = Source.Opportunity__c,
        Target.Invoicedescription__c = Source.Invoicedescription__c,
        Target.Description__c = Source.Description__c,
        Target.RecurringBillableOid__c = Source.RecurringBillableOid__c,
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
        Target.NextPaymentTotalAmount__c = Source.NextPaymentTotalAmount__c,
        Target.LastChangeOperator__c = Source.LastChangeOperator__c,
		Target.LastChangeDateTime__c = Source.LastChangeDateTime__c

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
        NextPaymentTotalAmount__c,
        LastChangeOperator__c,
		LastChangeDateTime__c
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
        Source.NextPaymentTotalAmount__c,
        Source.LastChangeOperator__c,
		Source.LastChangeDateTime__c
    );
