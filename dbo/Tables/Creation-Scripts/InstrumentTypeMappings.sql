SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[InstrumentTypeMappings](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ContractType] [nvarchar](14) COLLATE Latin1_General_CI_AS NOT NULL,
	[AccountingTreatment] [nvarchar](21) COLLATE Latin1_General_CI_AS NOT NULL,
	[HoldingStatus] [nvarchar](13) COLLATE Latin1_General_CI_AS NULL,
	[IsBankQualified] [int] NOT NULL,
	[IsFloatingRate] [int] NOT NULL,
	[IsRevolving] [int] NOT NULL,
	[TransactionType] [nvarchar](32) COLLATE Latin1_General_CI_AS NULL,
	[SOPStatus] [int] NOT NULL,
	[IsRecovery] [int] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[InstrumentTypeId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[FederalTaxExempt] [int] NOT NULL,
	[ProductType] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[IsNonAccrual] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[InstrumentTypeMappings]  WITH CHECK ADD  CONSTRAINT [EInstrumentTypeMapping_InstrumentType] FOREIGN KEY([InstrumentTypeId])
REFERENCES [dbo].[InstrumentTypes] ([Id])
GO
ALTER TABLE [dbo].[InstrumentTypeMappings] CHECK CONSTRAINT [EInstrumentTypeMapping_InstrumentType]
GO
