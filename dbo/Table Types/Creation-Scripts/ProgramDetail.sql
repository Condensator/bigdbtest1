CREATE TYPE [dbo].[ProgramDetail] AS TABLE(
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ActivationDate] [date] NULL,
	[DeactivationDate] [date] NULL,
	[Status] [nvarchar](11) COLLATE Latin1_General_CI_AS NOT NULL,
	[OverrideVendorFee] [bit] NOT NULL,
	[MaxQuoteExpirationDays] [int] NOT NULL,
	[IsCreatedFromVendor] [bit] NOT NULL,
	[ReceivableCodeId] [bigint] NULL,
	[FeeId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
