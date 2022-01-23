SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CPUPayoffs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[QuoteName] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsFullPayoff] [bit] NOT NULL,
	[PayoffDate] [date] NOT NULL,
	[Status] [nvarchar](9) COLLATE Latin1_General_CI_AS NOT NULL,
	[LeasePayoffQuoteNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[CPUContractId] [bigint] NOT NULL,
	[OldCPUFinanceId] [bigint] NOT NULL,
	[ContractAmendmentReasonCodeId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CPUFinanceId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CPUPayoffs]  WITH CHECK ADD  CONSTRAINT [ECPUPayoff_ContractAmendmentReasonCode] FOREIGN KEY([ContractAmendmentReasonCodeId])
REFERENCES [dbo].[ContractAmendmentReasonCodes] ([Id])
GO
ALTER TABLE [dbo].[CPUPayoffs] CHECK CONSTRAINT [ECPUPayoff_ContractAmendmentReasonCode]
GO
ALTER TABLE [dbo].[CPUPayoffs]  WITH CHECK ADD  CONSTRAINT [ECPUPayoff_CPUContract] FOREIGN KEY([CPUContractId])
REFERENCES [dbo].[CPUContracts] ([Id])
GO
ALTER TABLE [dbo].[CPUPayoffs] CHECK CONSTRAINT [ECPUPayoff_CPUContract]
GO
ALTER TABLE [dbo].[CPUPayoffs]  WITH CHECK ADD  CONSTRAINT [ECPUPayoff_CPUFinance] FOREIGN KEY([CPUFinanceId])
REFERENCES [dbo].[CPUFinances] ([Id])
GO
ALTER TABLE [dbo].[CPUPayoffs] CHECK CONSTRAINT [ECPUPayoff_CPUFinance]
GO
ALTER TABLE [dbo].[CPUPayoffs]  WITH CHECK ADD  CONSTRAINT [ECPUPayoff_OldCPUFinance] FOREIGN KEY([OldCPUFinanceId])
REFERENCES [dbo].[CPUFinances] ([Id])
GO
ALTER TABLE [dbo].[CPUPayoffs] CHECK CONSTRAINT [ECPUPayoff_OldCPUFinance]
GO
