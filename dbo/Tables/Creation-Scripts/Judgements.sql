SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Judgements](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[JudgementNumber] [bigint] NOT NULL,
	[Status] [nvarchar](15) COLLATE Latin1_General_CI_AS NULL,
	[JudgementDate] [date] NULL,
	[Amount_Amount] [decimal](16, 2) NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[Fees_Amount] [decimal](16, 2) NULL,
	[Fees_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[TotalAmount_Amount] [decimal](16, 2) NULL,
	[TotalAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IsDomesticated] [bit] NOT NULL,
	[InterestRate] [decimal](5, 2) NULL,
	[InterestGrantedFromDate] [date] NULL,
	[Comments] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[IsAmended] [bit] NOT NULL,
	[AmendedDate] [date] NULL,
	[AmendedAmount_Amount] [decimal](16, 2) NULL,
	[AmendedAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IsAmendedAmountSettled] [bit] NOT NULL,
	[ExpirationDate] [date] NULL,
	[RenewalDate] [date] NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ContractId] [bigint] NOT NULL,
	[CourtId] [bigint] NULL,
	[CourtFilingId] [bigint] NULL,
	[CourtFilingActionId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[Judgements]  WITH CHECK ADD  CONSTRAINT [EJudgement_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[Judgements] CHECK CONSTRAINT [EJudgement_Contract]
GO
ALTER TABLE [dbo].[Judgements]  WITH CHECK ADD  CONSTRAINT [EJudgement_Court] FOREIGN KEY([CourtId])
REFERENCES [dbo].[Courts] ([Id])
GO
ALTER TABLE [dbo].[Judgements] CHECK CONSTRAINT [EJudgement_Court]
GO
ALTER TABLE [dbo].[Judgements]  WITH CHECK ADD  CONSTRAINT [EJudgement_CourtFiling] FOREIGN KEY([CourtFilingId])
REFERENCES [dbo].[CourtFilings] ([Id])
GO
ALTER TABLE [dbo].[Judgements] CHECK CONSTRAINT [EJudgement_CourtFiling]
GO
ALTER TABLE [dbo].[Judgements]  WITH CHECK ADD  CONSTRAINT [EJudgement_CourtFilingAction] FOREIGN KEY([CourtFilingActionId])
REFERENCES [dbo].[CourtFilingActions] ([Id])
GO
ALTER TABLE [dbo].[Judgements] CHECK CONSTRAINT [EJudgement_CourtFilingAction]
GO
