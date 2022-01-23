SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DealProductTypes](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](32) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[GLSegmentValue] [nvarchar](12) COLLATE Latin1_General_CI_AS NOT NULL,
	[CapitalLeaseType] [nvarchar](16) COLLATE Latin1_General_CI_AS NULL,
	[LeaseType] [nvarchar](10) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[DealTypeId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[Code] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DealProductTypes]  WITH CHECK ADD  CONSTRAINT [EDealType_DealProductTypes] FOREIGN KEY([DealTypeId])
REFERENCES [dbo].[DealTypes] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DealProductTypes] CHECK CONSTRAINT [EDealType_DealProductTypes]
GO
