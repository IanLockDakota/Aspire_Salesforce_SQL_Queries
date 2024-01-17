/*
- CAN'T IDENTIFY MATCHING OBJECT WITHIN SF, PAYMENT DOESN'T SEEM TO MATCH THIS?
*/

WITH CurrentDaySnapshot AS (
    SELECT        Contract.ContractId, OppIdTable.OppurtunityID, Contract.ContractOid, CDue.[Current Due], PDue.[Past Due], MDueWOtax.[Misc Due], TDueWtax.[Total Due], LPayment.EffectiveDate, LPayment.ReferenceNumber, OldRentDue.[Oldest Rent Due], 
                         DPD.[Days Delinquent], PayRtn.[# Payments Returned], NxtPay.Amount, NxtPay.Tax, NxtPay.Total
FROM            Contract LEFT OUTER JOIN
                                (SELECT c.ContractOID, GV.ref_oid, GF.descr, ISNULL((GV.field_value), 'NULL') AS OppurtunityID
                                  FROM GenericField GF 
                                  LEFT OUTER JOIN GenericValue GV ON GF.oid = GV.genf_oid LEFT OUTER JOIN
                                  Contract c ON c.ContractOid = gv.ref_oid
                                  WHERE GF.oid = 23
                                  GROUP BY c.ContractOID, GV.ref_oid, GF.descr, GV.field_value
                                ) AS OppIDTable ON contract.ContractOid = OppIDTable.ref_oid LEFT OUTER JOIN
                             (SELECT        Payment.ContractOid, Payment.ReferenceNumber, Payment.EffectiveDate
                               FROM            Payment INNER JOIN
                                                             (SELECT        ContractOid, MAX(EffectiveDate) AS [Last Pymt Rcvd]
                                                               FROM            Payment AS Payment_1
                                                               WHERE        (IsPosted = 1) AND (IsReturned = 0)
                                                               GROUP BY ContractOid) AS EffDT ON Payment.ContractOid = EffDT.ContractOid AND Payment.EffectiveDate = EffDT.[Last Pymt Rcvd]
                               WHERE        (Payment.IsPosted = 1) AND (Payment.IsReturned = 0)) AS LPayment ON Contract.ContractOid = LPayment.ContractOid LEFT OUTER JOIN
                             (SELECT        ContractOid, COUNT(IsReturned) AS [# Payments Returned]
                               FROM            Payment AS Payment_2
                               GROUP BY ContractOid) AS PayRtn ON Contract.ContractOid = PayRtn.ContractOid LEFT OUTER JOIN
                             (SELECT        PaymentStream.ContractOid, SUM(PaymentStreamContractItem.Amount) AS Amount, SUM(PaymentStreamContractItem.OnStreamTaxAmount) AS Tax, SUM(PaymentStreamContractItem.Amount) 
                                                         + SUM(PaymentStreamContractItem.OnStreamTaxAmount) AS Total
                               FROM            PaymentStream INNER JOIN
                                                         PaymentStreamContractItem ON PaymentStream.PaymentStreamOid = PaymentStreamContractItem.PaymentStreamOid INNER JOIN
                                                             (SELECT        PaymentStream_1.ContractOid, MIN(PaymentStream_1.StartDate) AS SDate
                                                               FROM            PaymentStream AS PaymentStream_1 INNER JOIN
                                                                                         PaymentStreamContractItem AS PaymentStreamContractItem_1 ON PaymentStream_1.PaymentStreamOid = PaymentStreamContractItem_1.PaymentStreamOid
                                                               WHERE        (NOT (PaymentStream_1.ContractTermOid IS NULL)) AND (PaymentStream_1.IsInvoiced = 0)
                                                               GROUP BY PaymentStream_1.ContractOid) AS SstartDT ON PaymentStream.ContractOid = SstartDT.ContractOid AND PaymentStream.StartDate = SstartDT.SDate
                               WHERE        (NOT (PaymentStream.ContractTermOid IS NULL)) AND (PaymentStream.IsInvoiced = 0)
                               GROUP BY PaymentStream.ContractOid) AS NxtPay ON Contract.ContractOid = NxtPay.ContractOid LEFT OUTER JOIN
                             (SELECT        InvoiceDetail_1.ContractOid, CAST(CASE WHEN MAX(InvoiceDetail_1.DueDate) >= GETDATE() THEN 0 ELSE GETDATE() - MAX(InvoiceDetail_1.DueDate) END AS Int) AS [Days Delinquent]
                               FROM            InvoiceHeader AS InvoiceHeader_1 RIGHT OUTER JOIN
                                                         InvoiceDetail AS InvoiceDetail_1 INNER JOIN
                                                         TransactionCode AS TransactionCode_1 ON InvoiceDetail_1.TransactionCodeOid = TransactionCode_1.TransactionCodeOid ON InvoiceHeader_1.InvoiceHeaderOid = InvoiceDetail_1.InvoiceHeaderOid
                               WHERE        (InvoiceHeader_1.IsPosted = 1) AND (NOT (InvoiceDetail_1.OpenClosedOid IN (11022, 11023))) AND (TransactionCode_1.TransactionCodeOid IN (1, 35)) AND (NOT (InvoiceDetail_1.CurrentDueAmount = 0))
                               GROUP BY InvoiceDetail_1.ContractOid) AS DPD ON Contract.ContractOid = DPD.ContractOid LEFT OUTER JOIN
                             (SELECT        InvoiceDetail_4.ContractOid, SUM(InvoiceDetail_4.CurrentDueAmount) AS [Total Due]
                               FROM            InvoiceHeader AS InvoiceHeader_4 RIGHT OUTER JOIN
                                                         InvoiceDetail AS InvoiceDetail_4 INNER JOIN
                                                         TransactionCode AS TransactionCode_4 ON InvoiceDetail_4.TransactionCodeOid = TransactionCode_4.TransactionCodeOid ON InvoiceHeader_4.InvoiceHeaderOid = InvoiceDetail_4.InvoiceHeaderOid
                               WHERE        (InvoiceHeader_4.IsPosted = 1) AND (NOT (InvoiceDetail_4.OpenClosedOid IN (11022, 11023))) AND (NOT (InvoiceDetail_4.CurrentDueAmount = 0))
                               GROUP BY InvoiceDetail_4.ContractOid) AS TDueWtax ON Contract.ContractOid = TDueWtax.ContractOid LEFT OUTER JOIN
                             (SELECT        InvoiceDetail.ContractOid, SUM(InvoiceDetail.CurrentDueAmount) AS [Current Due]
                               FROM            InvoiceHeader RIGHT OUTER JOIN
                                                         InvoiceDetail INNER JOIN
                                                         TransactionCode ON InvoiceDetail.TransactionCodeOid = TransactionCode.TransactionCodeOid ON InvoiceHeader.InvoiceHeaderOid = InvoiceDetail.InvoiceHeaderOid
                               WHERE        (InvoiceHeader.IsPosted = 1) AND (NOT (InvoiceDetail.OpenClosedOid IN (11022, 11023))) AND (TransactionCode.TransactionCodeOid IN (1, 35, 4)) AND (NOT (InvoiceDetail.CurrentDueAmount = 0)) AND 
                                                         (InvoiceDetail.DueDate >= GETDATE())
                               GROUP BY InvoiceDetail.ContractOid) AS CDue ON Contract.ContractOid = CDue.ContractOid LEFT OUTER JOIN
                             (SELECT        InvoiceDetail_2.ContractOid, MAX(InvoiceDetail_2.DueDate) AS [Oldest Rent Due]
                               FROM            InvoiceHeader AS InvoiceHeader_2 RIGHT OUTER JOIN
                                                         InvoiceDetail AS InvoiceDetail_2 INNER JOIN
                                                         TransactionCode AS TransactionCode_2 ON InvoiceDetail_2.TransactionCodeOid = TransactionCode_2.TransactionCodeOid ON InvoiceHeader_2.InvoiceHeaderOid = InvoiceDetail_2.InvoiceHeaderOid
                               WHERE        (InvoiceHeader_2.IsPosted = 1) AND (NOT (InvoiceDetail_2.OpenClosedOid IN (11022, 11023))) AND (TransactionCode_2.TransactionCodeOid IN (1, 35)) AND (NOT (InvoiceDetail_2.CurrentDueAmount = 0))
                               GROUP BY InvoiceDetail_2.ContractOid) AS OldRentDue ON Contract.ContractOid = OldRentDue.ContractOid LEFT OUTER JOIN
                             (SELECT        InvoiceDetail_3.ContractOid, SUM(InvoiceDetail_3.CurrentDueAmount) AS [Misc Due]
                               FROM            InvoiceHeader AS InvoiceHeader_3 RIGHT OUTER JOIN
                                                         InvoiceDetail AS InvoiceDetail_3 INNER JOIN
                                                         TransactionCode AS TransactionCode_3 ON InvoiceDetail_3.TransactionCodeOid = TransactionCode_3.TransactionCodeOid ON InvoiceHeader_3.InvoiceHeaderOid = InvoiceDetail_3.InvoiceHeaderOid
                               WHERE        (InvoiceHeader_3.IsPosted = 1) AND (NOT (InvoiceDetail_3.OpenClosedOid IN (11022, 11023))) AND (NOT (TransactionCode_3.TransactionCodeOid IN (1, 35, 4))) AND (NOT (InvoiceDetail_3.CurrentDueAmount = 0))
                               GROUP BY InvoiceDetail_3.ContractOid) AS MDueWOtax ON Contract.ContractOid = MDueWOtax.ContractOid LEFT OUTER JOIN
                             (SELECT        InvoiceDetail_5.ContractOid, SUM(InvoiceDetail_5.CurrentDueAmount) AS [Past Due]
                               FROM            InvoiceHeader AS InvoiceHeader_5 RIGHT OUTER JOIN
                                                         InvoiceDetail AS InvoiceDetail_5 INNER JOIN
                                                         TransactionCode AS TransactionCode_5 ON InvoiceDetail_5.TransactionCodeOid = TransactionCode_5.TransactionCodeOid ON InvoiceHeader_5.InvoiceHeaderOid = InvoiceDetail_5.InvoiceHeaderOid
                               WHERE        (InvoiceHeader_5.IsPosted = 1) AND (NOT (InvoiceDetail_5.OpenClosedOid IN (11022, 11023))) AND (TransactionCode_5.TransactionCodeOid IN (1, 35, 4)) AND (NOT (InvoiceDetail_5.CurrentDueAmount = 0)) AND 
                                                         (InvoiceDetail_5.DueDate < GETDATE())
                               GROUP BY InvoiceDetail_5.ContractOid) AS PDue ON Contract.ContractOid = PDue.ContractOid 
),
PreviousDaySnapshot AS ( /* CHANGE TO SALESFORCE DATA */
    SELECT        Contract.ContractId, OppIdTable.OppurtunityID, Contract.ContractOid, CDue.[Current Due], PDue.[Past Due], MDueWOtax.[Misc Due], TDueWtax.[Total Due], LPayment.EffectiveDate, LPayment.ReferenceNumber, OldRentDue.[Oldest Rent Due], 
                         DPD.[Days Delinquent], PayRtn.[# Payments Returned], NxtPay.Amount, NxtPay.Tax, NxtPay.Total
FROM            Contract LEFT OUTER JOIN
                                (SELECT c.ContractOID, GV.ref_oid, GF.descr, ISNULL((GV.field_value), 'NULL') AS OppurtunityID
                                  FROM GenericField GF 
                                  LEFT OUTER JOIN GenericValue GV ON GF.oid = GV.genf_oid LEFT OUTER JOIN
                                  Contract c ON c.ContractOid = gv.ref_oid
                                  WHERE GF.oid = 23
                                  GROUP BY c.ContractOID, GV.ref_oid, GF.descr, GV.field_value
                                ) AS OppIDTable ON contract.ContractOid = OppIDTable.ref_oid LEFT OUTER JOIN
                             (SELECT        Payment.ContractOid, Payment.ReferenceNumber, Payment.EffectiveDate
                               FROM            Payment INNER JOIN
                                                             (SELECT        ContractOid, MAX(EffectiveDate) AS [Last Pymt Rcvd]
                                                               FROM            Payment AS Payment_1
                                                               WHERE        (IsPosted = 1) AND (IsReturned = 0)
                                                               GROUP BY ContractOid) AS EffDT ON Payment.ContractOid = EffDT.ContractOid AND Payment.EffectiveDate = EffDT.[Last Pymt Rcvd]
                               WHERE        (Payment.IsPosted = 1) AND (Payment.IsReturned = 0)) AS LPayment ON Contract.ContractOid = LPayment.ContractOid LEFT OUTER JOIN
                             (SELECT        ContractOid, COUNT(IsReturned) AS [# Payments Returned]
                               FROM            Payment AS Payment_2
                               GROUP BY ContractOid) AS PayRtn ON Contract.ContractOid = PayRtn.ContractOid LEFT OUTER JOIN
                             (SELECT        PaymentStream.ContractOid, SUM(PaymentStreamContractItem.Amount) AS Amount, SUM(PaymentStreamContractItem.OnStreamTaxAmount) AS Tax, SUM(PaymentStreamContractItem.Amount) 
                                                         + SUM(PaymentStreamContractItem.OnStreamTaxAmount) AS Total
                               FROM            PaymentStream INNER JOIN
                                                         PaymentStreamContractItem ON PaymentStream.PaymentStreamOid = PaymentStreamContractItem.PaymentStreamOid INNER JOIN
                                                             (SELECT        PaymentStream_1.ContractOid, MIN(PaymentStream_1.StartDate) AS SDate
                                                               FROM            PaymentStream AS PaymentStream_1 INNER JOIN
                                                                                         PaymentStreamContractItem AS PaymentStreamContractItem_1 ON PaymentStream_1.PaymentStreamOid = PaymentStreamContractItem_1.PaymentStreamOid
                                                               WHERE        (NOT (PaymentStream_1.ContractTermOid IS NULL)) AND (PaymentStream_1.IsInvoiced = 0)
                                                               GROUP BY PaymentStream_1.ContractOid) AS SstartDT ON PaymentStream.ContractOid = SstartDT.ContractOid AND PaymentStream.StartDate = SstartDT.SDate
                               WHERE        (NOT (PaymentStream.ContractTermOid IS NULL)) AND (PaymentStream.IsInvoiced = 0)
                               GROUP BY PaymentStream.ContractOid) AS NxtPay ON Contract.ContractOid = NxtPay.ContractOid LEFT OUTER JOIN
                             (SELECT        InvoiceDetail_1.ContractOid, CAST(CASE WHEN MAX(InvoiceDetail_1.DueDate) >= GETDATE() THEN 0 ELSE GETDATE() - MAX(InvoiceDetail_1.DueDate) END AS Int) AS [Days Delinquent]
                               FROM            InvoiceHeader AS InvoiceHeader_1 RIGHT OUTER JOIN
                                                         InvoiceDetail AS InvoiceDetail_1 INNER JOIN
                                                         TransactionCode AS TransactionCode_1 ON InvoiceDetail_1.TransactionCodeOid = TransactionCode_1.TransactionCodeOid ON InvoiceHeader_1.InvoiceHeaderOid = InvoiceDetail_1.InvoiceHeaderOid
                               WHERE        (InvoiceHeader_1.IsPosted = 1) AND (NOT (InvoiceDetail_1.OpenClosedOid IN (11022, 11023))) AND (TransactionCode_1.TransactionCodeOid IN (1, 35)) AND (NOT (InvoiceDetail_1.CurrentDueAmount = 0))
                               GROUP BY InvoiceDetail_1.ContractOid) AS DPD ON Contract.ContractOid = DPD.ContractOid LEFT OUTER JOIN
                             (SELECT        InvoiceDetail_4.ContractOid, SUM(InvoiceDetail_4.CurrentDueAmount) AS [Total Due]
                               FROM            InvoiceHeader AS InvoiceHeader_4 RIGHT OUTER JOIN
                                                         InvoiceDetail AS InvoiceDetail_4 INNER JOIN
                                                         TransactionCode AS TransactionCode_4 ON InvoiceDetail_4.TransactionCodeOid = TransactionCode_4.TransactionCodeOid ON InvoiceHeader_4.InvoiceHeaderOid = InvoiceDetail_4.InvoiceHeaderOid
                               WHERE        (InvoiceHeader_4.IsPosted = 1) AND (NOT (InvoiceDetail_4.OpenClosedOid IN (11022, 11023))) AND (NOT (InvoiceDetail_4.CurrentDueAmount = 0))
                               GROUP BY InvoiceDetail_4.ContractOid) AS TDueWtax ON Contract.ContractOid = TDueWtax.ContractOid LEFT OUTER JOIN
                             (SELECT        InvoiceDetail.ContractOid, SUM(InvoiceDetail.CurrentDueAmount) AS [Current Due]
                               FROM            InvoiceHeader RIGHT OUTER JOIN
                                                         InvoiceDetail INNER JOIN
                                                         TransactionCode ON InvoiceDetail.TransactionCodeOid = TransactionCode.TransactionCodeOid ON InvoiceHeader.InvoiceHeaderOid = InvoiceDetail.InvoiceHeaderOid
                               WHERE        (InvoiceHeader.IsPosted = 1) AND (NOT (InvoiceDetail.OpenClosedOid IN (11022, 11023))) AND (TransactionCode.TransactionCodeOid IN (1, 35, 4)) AND (NOT (InvoiceDetail.CurrentDueAmount = 0)) AND 
                                                         (InvoiceDetail.DueDate >= GETDATE())
                               GROUP BY InvoiceDetail.ContractOid) AS CDue ON Contract.ContractOid = CDue.ContractOid LEFT OUTER JOIN
                             (SELECT        InvoiceDetail_2.ContractOid, MAX(InvoiceDetail_2.DueDate) AS [Oldest Rent Due]
                               FROM            InvoiceHeader AS InvoiceHeader_2 RIGHT OUTER JOIN
                                                         InvoiceDetail AS InvoiceDetail_2 INNER JOIN
                                                         TransactionCode AS TransactionCode_2 ON InvoiceDetail_2.TransactionCodeOid = TransactionCode_2.TransactionCodeOid ON InvoiceHeader_2.InvoiceHeaderOid = InvoiceDetail_2.InvoiceHeaderOid
                               WHERE        (InvoiceHeader_2.IsPosted = 1) AND (NOT (InvoiceDetail_2.OpenClosedOid IN (11022, 11023))) AND (TransactionCode_2.TransactionCodeOid IN (1, 35)) AND (NOT (InvoiceDetail_2.CurrentDueAmount = 0))
                               GROUP BY InvoiceDetail_2.ContractOid) AS OldRentDue ON Contract.ContractOid = OldRentDue.ContractOid LEFT OUTER JOIN
                             (SELECT        InvoiceDetail_3.ContractOid, SUM(InvoiceDetail_3.CurrentDueAmount) AS [Misc Due]
                               FROM            InvoiceHeader AS InvoiceHeader_3 RIGHT OUTER JOIN
                                                         InvoiceDetail AS InvoiceDetail_3 INNER JOIN
                                                         TransactionCode AS TransactionCode_3 ON InvoiceDetail_3.TransactionCodeOid = TransactionCode_3.TransactionCodeOid ON InvoiceHeader_3.InvoiceHeaderOid = InvoiceDetail_3.InvoiceHeaderOid
                               WHERE        (InvoiceHeader_3.IsPosted = 1) AND (NOT (InvoiceDetail_3.OpenClosedOid IN (11022, 11023))) AND (NOT (TransactionCode_3.TransactionCodeOid IN (1, 35, 4))) AND (NOT (InvoiceDetail_3.CurrentDueAmount = 0))
                               GROUP BY InvoiceDetail_3.ContractOid) AS MDueWOtax ON Contract.ContractOid = MDueWOtax.ContractOid LEFT OUTER JOIN
                             (SELECT        InvoiceDetail_5.ContractOid, SUM(InvoiceDetail_5.CurrentDueAmount) AS [Past Due]
                               FROM            InvoiceHeader AS InvoiceHeader_5 RIGHT OUTER JOIN
                                                         InvoiceDetail AS InvoiceDetail_5 INNER JOIN
                                                         TransactionCode AS TransactionCode_5 ON InvoiceDetail_5.TransactionCodeOid = TransactionCode_5.TransactionCodeOid ON InvoiceHeader_5.InvoiceHeaderOid = InvoiceDetail_5.InvoiceHeaderOid
                               WHERE        (InvoiceHeader_5.IsPosted = 1) AND (NOT (InvoiceDetail_5.OpenClosedOid IN (11022, 11023))) AND (TransactionCode_5.TransactionCodeOid IN (1, 35, 4)) AND (NOT (InvoiceDetail_5.CurrentDueAmount = 0)) AND 
                                                         (InvoiceDetail_5.DueDate < GETDATE())
                               GROUP BY InvoiceDetail_5.ContractOid) AS PDue ON Contract.ContractOid = PDue.ContractOid 
)

SELECT *
FROM (
    SELECT
		CASE WHEN CurrentDay.[# Payments Returned] <> PreviousDay.[# Payments Returned]
            THEN 'Data Changed' 
            ELSE 'No Changes'
        END AS ChangeStatus,
        Contract.ContractOid AS ContractID,        
        Contract.Contractid AS ContractOID,
        CurrentDay.OppurtunityID As OppurtunityID,
        CurrentDay.[Current Due] AS [Current Amount Due],
        CurrentDay.[Past Due] AS [Past Amount Due],
        CurrentDay.[Misc Due] AS [Misc Amount Due],
        CurrentDay.[Total Due] AS [Total Amount Due],
        CurrentDay.EffectiveDate AS [Effective Date],
        CurrentDay.ReferenceNumber AS [Reference Number],
        CurrentDay.[Days Delinquent] AS [Days Delinquent],
        CurrentDay.[# Payments Returned] AS [# of Payments Returned],
        CurrentDay.Amount AS [Payment Amount],
        CurrentDay.Tax AS [Payment Tax],
        CurrentDay.Total AS [Payment Total]
    FROM 
        Contract
    LEFT OUTER JOIN
        CurrentDaySnapshot AS CurrentDay ON Contract.ContractOid = CurrentDay.ContractOid
    LEFT OUTER JOIN
        PreviousDaySnapshot AS PreviousDay ON Contract.ContractOid = PreviousDay.ContractOid
    WHERE
        (Contract.IsBooked = 1) AND (Contract.CompanyOid = 1)
) AS Subquery
/*WHERE
    ChangeStatus = 'Data Changed'*/
ORDER BY 
    ContractOid;