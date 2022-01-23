CREATE TYPE [dbo].[VendorAssetByContractReportTemplate] AS TABLE(
	[Name] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[SequenceNumber] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[ContractFilterOption] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[Location] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[State] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[Country] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[ContractStatus] [nvarchar](16) COLLATE Latin1_General_CI_AS NULL,
	[CommencementDate] [date] NULL,
	[CommencementDateOptions] [nvarchar](17) COLLATE Latin1_General_CI_AS NULL,
	[FromCommencementDate] [date] NULL,
	[ToCommencementDate] [date] NULL,
	[CommencementUpThrough] [date] NULL,
	[CommencementRunDate] [int] NULL,
	[MaturityDateOptions] [nvarchar](17) COLLATE Latin1_General_CI_AS NULL,
	[MaturityTillXDaysFromRunDate] [int] NULL,
	[MaturityDate] [date] NULL,
	[FromMaturityDate] [date] NULL,
	[ToMaturityDate] [date] NULL,
	[MaturityTillDate] [date] NULL,
	[SerialNumber] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[OrderBy] [nvarchar](21) COLLATE Latin1_General_CI_AS NOT NULL,
	[AssetAlias] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[Manufacturer] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[PartNumber] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[ModelYear] [decimal](4, 0) NULL,
	[Status] [nvarchar](17) COLLATE Latin1_General_CI_AS NULL,
	[AssetType] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[Term] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[CustomerName] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[CustomerNumber] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[UDF1Value] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[UDF2Value] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[UDF3Value] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[UDF4Value] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[UDF5Value] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[CustomerId] [bigint] NULL,
	[VendorId] [bigint] NULL,
	[UserId] [bigint] NULL,
	[AssetId] [bigint] NULL,
	[FromSequenceNumberId] [bigint] NULL,
	[ToSequenceNumberId] [bigint] NULL,
	[ProgramVendorId] [bigint] NULL,
	[DealerOrDistributerId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO