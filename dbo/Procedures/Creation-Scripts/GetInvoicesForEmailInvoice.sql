SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetInvoicesForEmailInvoice]
(
@ProcessThroughDate DATE
,@CurrentBusinessDate DATE
,@IsInvoiceSensitive BIT = 0
,@BusinessCalender NVARCHAR(40)
,@SendMail BIT = 0
)
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
Declare @PreviousBusinessDate Date
IF(@BusinessCalender IS NOT NULL)
BEGIN
SELECT @PreviousBusinessDate = MAX(bcd.BusinessDate) FROM BusinessCalendars bc join BusinessCalendarDetails bcd on bc.Id = bcd.BusinessCalendarId
where bc.Name = @BusinessCalender  AND bcd.IsWeekday = 'true'
AND bcd.IsHoliday = 'false' AND bcd.BusinessDate < @CurrentBusinessDate
END
SELECT DISTINCT
p.Id CustomerId,
ri.Id InvoiceId,
bt.Id BillToId,
bt.Name BillToName,
le.Id LegalEntityId,
bt.SendCCEmailNotificationTo CCEmailAddress,
bt.SendEmailNotificationTo ToEMailAddress,
bt.SendBccEmailNotificationTo BCCEmailAddress,
bt.CustomerBillToName CustomerNameonInvoice,
ri.Number InvoiceNumber,
ri.DueDate InvoiceDate,
le.Name LegalEntityName,
p.PartyNumber PartyNumber,
ri.InvoiceFile_Source InvoiceFileSource,
ri.InvoiceFile_Type InvoiceFileType,
ri.InvoiceFile_Content InvoiceFileContent,
ri.IsPrivateLabel IsPrivateLabel,
p.PartyName CustomerName,
ri.OriginationSource OriginationSource,
ri.OriginationSourceId OriginationSourceId,
LOWER(rt.DefaultFromEmail) FromEmail,
et.Name InvoiceEmailTemplate,
bif.InvoiceEmailTemplateId InvoiceEmailTemplateId
FROM
ReceivableInvoices ri
JOIN Parties p ON ri.CustomerId = p.Id
JOIN Customers c ON p.Id = c.Id
JOIN LegalEntities le ON ri.LegalEntityId = le.Id
JOIN RemitToes rt ON ri.RemitToId = rt.Id
JOIN BillToes bt ON ri.BillToId = bt.Id
--JOIN ReceivableCategories rc ON ri.ReceivableCategoryId = rc.Id
JOIN BillToInvoiceFormats bif ON ri.BillToId = bif.BillToId
AND bt.Id = bif.BillToId
AND ri.ReportFormatId = bif.InvoiceFormatId
--AND rc.Name = bif.ReceivableCategory
JOIN EmailTemplates et ON bif.InvoiceEmailTemplateId = et.Id
WHERE ri.IsActive = 1
AND ri.IsEmailSent = 0
AND ((@SendMail = 1 AND (ri.InvoiceRunDate >= @PreviousBusinessDate
AND ri.DueDate >= ri.InvoiceRunDate
AND ri.InvoiceRunDate <= CASE WHEN @IsInvoiceSensitive = 0 THEN @ProcessThroughDate ELSE DATEADD(DD,c.InvoiceLeadDays,@ProcessThroughDate) END))
OR @SendMail = 0)
AND bT.DeliverInvoiceViaEmail = 1
AND ri.InvoicePreference = 'GenerateAndDeliver'
AND c.DeliverInvoiceViaEmail = 1
AND ri.InvoiceFile_Content IS NOT NULL
AND bif.IsActive = 1
AND bif.InvoiceEmailTemplateId IS NOT NULL AND IsStatementInvoice = 0
UNION ALL
SELECT DISTINCT
p.Id CustomerId,
ri.Id InvoiceId,
bt.Id BillToId,
bt.Name BillToName,
le.Id LegalEntityId,
bt.SendCCEmailNotificationTo CCEmailAddress,
bt.SendEmailNotificationTo ToEMailAddress,
bt.SendBccEmailNotificationTo BCCEmailAddress,
bt.CustomerBillToName CustomerNameonInvoice,
ri.Number InvoiceNumber,
ri.DueDate InvoiceDate,
le.Name LegalEntityName,
p.PartyNumber PartyNumber,
ri.InvoiceFile_Source InvoiceFileSource,
ri.InvoiceFile_Type InvoiceFileType,
ri.InvoiceFile_Content InvoiceFileContent,
ri.IsPrivateLabel IsPrivateLabel,
p.PartyName CustomerName,
ri.OriginationSource OriginationSource,
ri.OriginationSourceId OriginationSourceId,
LOWER(rt.DefaultFromEmail) FromEmail,
et.Name InvoiceEmailTemplate,
bt.StatementInvoiceEmailTemplateId InvoiceEmailTemplateId
FROM
ReceivableInvoices ri
JOIN Parties p ON ri.CustomerId = p.Id
JOIN Customers c ON p.Id = c.Id
JOIN LegalEntities le ON ri.LegalEntityId = le.Id
JOIN RemitToes rt ON ri.RemitToId = rt.Id
JOIN BillToes bt ON ri.BillToId = bt.Id
JOIN EmailTemplates et ON bt.StatementInvoiceEmailTemplateId = et.Id
WHERE ri.IsActive = 1
AND ri.IsEmailSent = 0
AND ((@SendMail = 1 AND (ri.InvoiceRunDate >= @PreviousBusinessDate
AND ri.DueDate >= ri.InvoiceRunDate
AND ri.InvoiceRunDate <= CASE WHEN @IsInvoiceSensitive = 0 THEN @ProcessThroughDate ELSE DATEADD(DD,c.InvoiceLeadDays,@ProcessThroughDate) END))
OR @SendMail = 0)
AND bT.DeliverInvoiceViaEmail = 1
AND ri.InvoicePreference = 'GenerateAndDeliver'
AND c.DeliverInvoiceViaEmail = 1
AND ri.InvoiceFile_Content IS NOT NULL AND IsStatementInvoice = 1
AND bt.StatementInvoiceEmailTemplateId IS NOT NULL
END

GO
