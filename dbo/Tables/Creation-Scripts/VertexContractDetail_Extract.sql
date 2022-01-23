SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[VertexContractDetail_Extract](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ContractId] [bigint] NOT NULL,
	[SequenceNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsSyndicated] [bit] NOT NULL,
	[TaxRemittanceType] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[TaxAssessmentLevel] [nvarchar](10) COLLATE Latin1_General_CI_AS NOT NULL,
	[DealProductTypeId] [bigint] NULL,
	[LineofBusinessId] [bigint] NULL,
	[Term] [decimal](16, 2) NOT NULL,
	[BusCode] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[ShortLeaseType] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[IsContractCapitalizeUpfront] [bit] NOT NULL,
	[CommencementDate] [date] NULL,
	[LeaseFinanceId] [bigint] NOT NULL,
	[NumberOfInceptionPayments] [int] NOT NULL,
	[ClassificationContractType] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsLease] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[MaturityDate] [date] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
