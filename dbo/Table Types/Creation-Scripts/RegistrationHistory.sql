CREATE TYPE [dbo].[RegistrationHistory] AS TABLE(
	[RowNumber] [bigint] NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PlateNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[RegistrationCertificateNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[DateOfRegistration] [date] NULL,
	[DeliveredOn] [date] NULL,
	[IsActive] [bit] NULL,
	[EngineNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[EffectiveFromDate] [date] NULL,
	[EffectiveTillDate] [date] NULL,
	[PreviousLeaseAgreement] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[AssetId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
