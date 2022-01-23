SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MT940File_Dump](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[TransactionReferenceNumber] [nvarchar](16) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RelatedReference] [nvarchar](16) COLLATE Latin1_General_CI_AS NULL,
	[AccountIdentification] [nvarchar](35) COLLATE Latin1_General_CI_AS NULL,
	[StatementNumber] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[SequenceNumber] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[OpeningBalance_DC] [nvarchar](13) COLLATE Latin1_General_CI_AS NULL,
	[OpeningBalanceAsOf] [date] NULL,
	[OpeningBalance_Amount] [decimal](16, 2) NULL,
	[OpeningBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[ClosingBalance_DC] [nvarchar](13) COLLATE Latin1_General_CI_AS NULL,
	[ClosingBalanceAsOf] [date] NULL,
	[ClosingBalance_Amount] [decimal](16, 2) NULL,
	[ClosingBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[ClosingAvailableBalance_DC] [nvarchar](13) COLLATE Latin1_General_CI_AS NULL,
	[ClosingAvailableBalanceAsOf] [date] NULL,
	[ClosingAvailableBalance_Amount] [decimal](16, 2) NULL,
	[ClosingAvailableBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[TransValueDate] [date] NULL,
	[TransEntryDate] [date] NULL,
	[Trans_DC] [nvarchar](13) COLLATE Latin1_General_CI_AS NULL,
	[TransFundsCode] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[TransactionAmount_Amount] [decimal](16, 2) NULL,
	[TransactionAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[TransTypeIdCode] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[TransCustomerReference] [nvarchar](16) COLLATE Latin1_General_CI_AS NULL,
	[TransSupplementaryDetails] [nvarchar](34) COLLATE Latin1_General_CI_AS NULL,
	[TransBankReferenceNumber] [nvarchar](16) COLLATE Latin1_General_CI_AS NULL,
	[InformationToOwner] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[FileName] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[IsValid] [bit] NOT NULL,
	[JobStepInstanceId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[GUID] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
