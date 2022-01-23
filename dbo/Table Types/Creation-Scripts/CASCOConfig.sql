CREATE TYPE [dbo].[CASCOConfig] AS TABLE(
	[VehicleAgeFrom] [int] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[VehicleAgeTo] [int] NOT NULL,
	[InternalDealer] [decimal](5, 2) NOT NULL,
	[ExternalDealer] [decimal](5, 2) NOT NULL,
	[IsActive] [bit] NULL,
	[InsuranceCompanyId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
