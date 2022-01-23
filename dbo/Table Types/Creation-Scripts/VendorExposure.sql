CREATE TYPE [dbo].[VendorExposure] AS TABLE(
	[OwnedDirectExposure_Amount] [decimal](24, 2) NOT NULL,
	[OwnedDirectExposure_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[OwnedIndirectExposure_Amount] [decimal](24, 2) NOT NULL,
	[OwnedIndirectExposure_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[SyndicatedDirectExposure_Amount] [decimal](24, 2) NOT NULL,
	[SyndicatedDirectExposure_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[SyndicatedIndirectExposure_Amount] [decimal](24, 2) NOT NULL,
	[SyndicatedIndirectExposure_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[TotalVendorExposure_Amount] [decimal](24, 2) NOT NULL,
	[TotalVendorExposure_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[ExposureDate] [date] NULL,
	[ExposureVendorId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
