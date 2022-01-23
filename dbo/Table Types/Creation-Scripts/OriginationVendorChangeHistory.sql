CREATE TYPE [dbo].[OriginationVendorChangeHistory] AS TABLE(
	[TransferDate] [date] NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[EffectiveFromDate] [date] NULL,
	[IsCurrent] [bit] NOT NULL,
	[NewOriginationVendorId] [bigint] NULL,
	[NewProgramVendorId] [bigint] NULL,
	[NewRemitToId] [bigint] NULL,
	[OldOriginationVendorId] [bigint] NULL,
	[OldProgramVendorId] [bigint] NULL,
	[OldRemitToId] [bigint] NULL,
	[ContractId] [bigint] NULL,
	[OpportunityId] [bigint] NULL,
	[CreditProfileId] [bigint] NULL,
	[OldProgramId] [bigint] NULL,
	[NewProgramId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
