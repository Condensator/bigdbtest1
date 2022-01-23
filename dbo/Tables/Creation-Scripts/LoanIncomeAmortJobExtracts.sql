SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LoanIncomeAmortJobExtracts](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[LoanFinanceId] [bigint] NOT NULL,
	[TaskChunkServiceInstanceId] [bigint] NULL,
	[JobInstanceId] [bigint] NOT NULL,
	[IsSubmitted] [bit] NOT NULL,
	[SequenceNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[ContractId] [bigint] NOT NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[InvoiceLeadDays] [int] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
