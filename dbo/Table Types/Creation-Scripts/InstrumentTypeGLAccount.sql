CREATE TYPE [dbo].[InstrumentTypeGLAccount] AS TABLE(
	[GLAccountNumber] [nvarchar](12) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[UseRollupCostCenter] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[ActivationDate] [date] NOT NULL,
	[DeactivationDate] [date] NULL,
	[InstrumentTypeId] [bigint] NOT NULL,
	[GLEntryItemId] [bigint] NOT NULL,
	[GLTemplateId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
